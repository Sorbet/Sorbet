#!/bin/bash

set -e

if [ "$1" = -t ]; then
    mode="test"
else
    mode="fix"
fi

cd "$(dirname "$0")/../.."

bazel build //tools:clang-format &> /dev/null

# shellcheck disable=SC2207
cxx_src=(
    $(git ls-files -c -m -o --exclude-standard -- '*.cxx' '*.cc' '*.h' | \
          grep -v ^third_party/
    )
)
misformatted=()

cleanup() {
    for src in "${cxx_src[@]}"; do
        rm -f "$src.formatted"
    done
}

trap cleanup EXIT

## uncomment the line below to dump format
#clang-format -style=file -dump-config

for src in "${cxx_src[@]}"; do
    bazel-bin/tools/clang-format -style=file "$src" > "$src.formatted"
    if ! cmp -s "$src" "$src.formatted"; then
        misformatted=("${misformatted[@]}" "$src")
        if [ "$mode" = "fix" ]; then
            cp "$src.formatted" "$src"
        fi
    fi

    rm -f "$src.formatted"
done

if [ "${#misformatted[@]}" -eq 0 ]; then
    exit 0
fi

if [ "$mode" = "fix" ]; then
    echo "Formatted the following files:" >&2
else
    echo -ne "\\e[1;31m" >&2
    echo "The following files are misformatted!" >&2
    echo -ne "\\e[0m" >&2
    echo -e "Run \\e[97;1;42m ./tools/scripts/format_cxx.sh \\e[0m to format." >&2
fi

for src in "${misformatted[@]}"; do
    echo "$src" >&2
done

exit 1
