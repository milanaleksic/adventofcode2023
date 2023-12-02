#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob globstar

# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export SCRIPT_DIR

zig build
BINARY="$SCRIPT_DIR/zig-out/bin/adventofcode2023"
for i in $(seq 1 25);
do
    if [ -e "data/input-${i}-1.txt" ]
    then
        $BINARY $i 1 data/input-${i}-1.txt
        if [ -e "data/input-${i}-2.txt" ]
        then
            $BINARY $i 2 data/input-${i}-2.txt
        else
            $BINARY $i 2 data/input-${i}-1.txt
        fi
    fi
done
