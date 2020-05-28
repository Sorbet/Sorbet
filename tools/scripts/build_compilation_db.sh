#!/bin/bash

set -e

cd "$(dirname "$0")/../.."

bazel build //tools:compdb -c opt
sed "s,__EXEC_ROOT__,$(pwd)/bazel-sorbet," bazel-bin/tools/compile_commands.json > compile_commands.json
