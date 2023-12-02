#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob globstar

# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export SCRIPT_DIR

zig build
$SCRIPT_DIR/zig-out/bin/adventofcode2023 1 1 data/input-1-1.txt
$SCRIPT_DIR/zig-out/bin/adventofcode2023 1 2 data/input-1-1.txt
$SCRIPT_DIR/zig-out/bin/adventofcode2023 2 1 data/input-2-1.txt
$SCRIPT_DIR/zig-out/bin/adventofcode2023 2 2 data/input-2-1.txt
