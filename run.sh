#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob globstar

# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export SCRIPT_DIR

echo 'building ReleaseFast...'
zig build -Doptimize=ReleaseFast

set +u
if [[ x"${GITHUB_STEP_SUMMARY}" == "x" ]]; then 
    output=$(mktemp)
else
    output=$GITHUB_STEP_SUMMARY
fi
set -u

run() {
    echo "\`\`\`" | tee -a "$4"
    ts=$(date +%s%N)
    "$SCRIPT_DIR/zig-out/bin/adventofcode2023" $1 $2 $3 2>&1 | tee -a "$4"
    echo "\`\`\`" | tee -a "$4"
    echo "Done in *$((($(date +%s%N) - $ts)/1000000))ms*" 2>&1 | tee -a "$4"
}

echo "**Starting to run the application in the release mode**" | tee -a "$output"
tsTotal=$(date +%s%N)
for i in $(seq 1 25);
do
    if [ -e "data/input-${i}-1.txt" ]
    then
        run $i 1 data/input-${i}-1.txt "$output"
        ts=$(date +%s%N)
        if [ -e "data/input-${i}-2.txt" ]
        then
            run $i 2 data/input-${i}-2.txt "$output"
        else
            run $i 2 data/input-${i}-1.txt "$output"
        fi
    fi
done
echo "Total time running: *$((($(date +%s%N) - $tsTotal)/1000000))ms*" | tee -a "$output"
echo "Additionally, output is available in $output"
