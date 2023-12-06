#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob globstar

# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export SCRIPT_DIR

echo 'building ReleaseFast...'
zig build -Doptimize=ReleaseFast

run() {
    ts=$(date +%s%N)
    "$SCRIPT_DIR/zig-out/bin/adventofcode2023" $1 $2 $3
    echo "Done in $((($(date +%s%N) - $ts)/1000000))ms"
}

echo 'running...'
tsTotal=$(date +%s%N)
for i in $(seq 1 25);
do
    if [ -e "data/input-${i}-1.txt" ]
    then
        run $i 1 data/input-${i}-1.txt
        ts=$(date +%s%N)
        if [ -e "data/input-${i}-2.txt" ]
        then
            run $i 2 data/input-${i}-2.txt
        else
            run $i 2 data/input-${i}-1.txt
        fi
    fi
done
echo "Total time running: $((($(date +%s%N) - $tsTotal)/1000000))ms"