#!/bin/bash

# Runs a single srb init test from gems/sorbet/test/snapshot/{partial,total}/*

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# Explicitly setting this after runfiles initialization
set -euo pipefail
shopt -s dotglob

# ----- Option parsing -----

# This script is always invoked by bazel at the repository root
repo_root="$PWD"

# Fix up runfiles dir so that it's stable when we change directories
export RUNFILES_DIR="$repo_root/$RUNFILES_DIR"

# these positional arguments are supplied in snapshot.bzl
ruby_package=$1
output_archive="${repo_root}/$2"
test_name=$3

# This is the root of the test -- the src and expected directories are
# sub-directories of this one.
test_dir="${repo_root}/gems/sorbet/test/snapshot/${test_name}"

# NOTE: using rlocation here because this script gets run from a genrule
# shellcheck disable=SC1090
source "$(rlocation com_stripe_ruby_typer/gems/sorbet/test/snapshot/logging.sh)"


# ----- Environment setup and validation -----

HOME=$test_dir
export HOME

BUNDLE_PATH="$test_dir/bundler"
export BUNDLE_PATH

XDG_CACHE_HOME="${test_dir}/cache"
export XDG_CACHE_HOME

if [[ "${test_name}" =~ partial/* ]]; then
  is_partial=1
else
  is_partial=
fi

info "├─ test_name:      ${test_name}"
info "├─ output_archive: ${output_archive}"
info "├─ is_partial:     ${is_partial:-0}"


# Add ruby to the path
RUBY_WRAPPER_LOC="$(rlocation "${ruby_package}/ruby")"
PATH="$(dirname "$RUBY_WRAPPER_LOC"):$PATH"
export PATH

# Disable ruby warnings to get consistent output between different ruby versions
RUBYOPT="-W0"
export RUBYOPT

info "├─ ruby:           $(command -v ruby)"
info "├─ ruby --version: $(ruby --version)"

# Add bundler to the path
BUNDLER_LOC="$(dirname "$(rlocation gems/bundler/bundle)")"
GEMS_LOC="$(dirname "$BUNDLER_LOC")/gems"
PATH="$BUNDLER_LOC:$PATH"
export PATH

info "├─ bundle:           $(command -v bundle)"
info "├─ bundle --version: $(bundle --version)"

# Use the sorbet executable built by bazel
SRB_SORBET_EXE="$(rlocation com_stripe_ruby_typer/main/sorbet)"
export SRB_SORBET_EXE

srb="${repo_root}/gems/sorbet/bin/srb"

info "├─ sorbet:           $SRB_SORBET_EXE"
info "├─ sorbet --version: $("$SRB_SORBET_EXE" --version)"

SORBET_TYPED_REV="$(rlocation com_stripe_ruby_typer/gems/sorbet/test/snapshot/sorbet-typed.rev)"
SRB_SORBET_TYPED_REVISION="$(<"$SORBET_TYPED_REV")"
export SRB_SORBET_TYPED_REVISION

if [ "$SRB_SORBET_TYPED_REVISION" = "" ]; then
  error "└─ empty sorbet-typed revision from: ${SORBET_TYPED_REV}"
  exit 1
else
  info "├─ sorbet-typed:     $SRB_SORBET_TYPED_REVISION"
fi


# ----- Build the test sandbox -----

# NOTE: this builds a replica of the `src` tree in the `actual` directory, and
# then uses that as a workspace.
actual="${test_dir}/actual"
cp -r "${test_dir}/src" "$actual"

cleanup() {
  rm -rf "$actual"
}

trap cleanup EXIT

# ----- Run the test -----

(
  cd "$actual"

  # Setup the vendor/cache directory to include all gems required for any test
  info "├─ Setting up vendor/cache"

  # NOTE: using "mkdir -p" just in case this is run outside of the sandbox
  # (like when --spawn_strategy=standalone is passed)
  mkdir -p vendor
  ln -sf "$GEMS_LOC" "vendor/cache"

  ruby_loc=$(bundle exec which ruby)
  if [[ "$ruby_loc" == "$RUBY_WRAPPER_LOC" ]] ; then
    info "├─ Bundle was able to find ruby"
  else 
    attn "├─ ruby in path:  ${ruby_loc}"
    attn "├─ expected ruby: ${RUBY_WRAPPER_LOC}"
    error "└─ Bundle failed to find ruby"
    exit 1
  fi

  # Configuring output to vendor/bundle
  # Passing --local to never consult rubygems.org
  # Passing --no-prune to not delete unused gems in vendor/cache
  info "├─ Installing dependencies to vendor/bundle"
  bundle install --local --no-prune

  info "├─ Checking installation"
  bundle check

  # Uses /dev/null for stdin so any binding.pry would exit immediately
  # (otherwise, pry will be waiting for input, but it's impossible to tell
  # because the pry output is hiding in the *.log files)
  #
  # note: redirects stderr before the pipe
  if ! SRB_YES=1 bundle exec "$srb" init < /dev/null 2> "err.log" > "out.log"; then
    error "├─ srb init failed."
    error "├─ stdout (out.log):"
    cat "out.log"
    error "├─ stderr (err.log):"
    cat "err.log"
    error "└─ (end stderr)"
    exit 1
  fi

  # FIXME: Removing hidden-definitions in actual to hide them from diff output.
  rm -rf "sorbet/rbi/hidden-definitions"

  # Fix up the logs to not have sandbox directories present.

  info "├─ Fixing up err.log"
  sed -i.bak \
    -e "s,${TMPDIR}[^ ]*/\([^/]*\),<tmp>/\1,g" \
    -e "s,${XDG_CACHE_HOME},<cache>,g" \
    -e "s,${HOME},<home>,g" \
    "err.log"

  info "├─ Fixing up out.log"
  sed -i.bak \
    -e 's/with [0-9]* modules and [0-9]* aliases/with X modules and Y aliases/' \
    -e "s,${TMPDIR}[^ ]*/\([^/]*\),<tmp>/\1,g" \
    -e "s,${XDG_CACHE_HOME},<cache>,g" \
    -e "s,${HOME},<home>,g" \
    "out.log"

)

(
  cd "$test_dir"

  info "├─ archiving results"

  # archive the test
  tar -cz -f "$output_archive" actual/{sorbet,err.log,out.log}
)

success "└─ done"
