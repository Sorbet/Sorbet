#!/bin/bash

tmp="$(mktemp -d)"
cwd="$(pwd)"
cd "$tmp" || exit 1
separator() {
    echo -------------------------
}

cp "$cwd"/test/cli/suggest-typed-true/*.rb "$tmp/"


"$cwd/main/sorbet" --silence-dev-message --suggest-typed --typed=false --isolate-error-code=7022 does-not-exist.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message --suggest-typed --typed=true --isolate-error-code=7022 does-not-exist.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict does-not-exist.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-true.rb 2>&1
separator

# Avoid error when repeating options
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict --isolate-error-code=7022 suggest-typed-true.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-ignore.rb 2>&1
cat suggest-typed-ignore.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-ignore.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-false.rb 2>&1
cat suggest-typed-false.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-false.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-true.rb 2>&1
cat suggest-typed-true.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-true.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-strict.rb 2>&1
cat suggest-typed-strict.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-strict.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-strong.rb 2>&1
cat suggest-typed-strong.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-strong.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict empty.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-with-too-low.rb 2>&1
cat suggest-typed-with-too-low.rb
separator

"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-with-too-low.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-already-ignore.rb 2>&1
cat suggest-typed-already-ignore.rb
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-already-autogenerated.rb 2>&1
cat suggest-typed-already-autogenerated.rb
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-shabang.rb 2>&1
cat suggest-typed-shabang.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-shabang.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-behaviour-over-multiple-1.rb suggest-typed-behaviour-over-multiple-2.rb 2>&1
cat suggest-typed-behaviour-over-multiple-1.rb
cat suggest-typed-behaviour-over-multiple-2.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-behaviour-over-multiple-1.rb suggest-typed-behaviour-over-multiple-2.rb 2>&1
separator

"$cwd/main/sorbet" --silence-dev-message -a --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-and-type.rb 2>&1
cat suggest-typed-and-type.rb
"$cwd/main/sorbet" --silence-dev-message --suggest-typed --isolate-error-code=7022 --typed=strict suggest-typed-and-type.rb 2>&1
separator

rm -r "$tmp"
