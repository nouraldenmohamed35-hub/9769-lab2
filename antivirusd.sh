#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs"
    exit 1
fi

dir="$1"
malicious_dir="$2"
interval="$3"
mkdir -p "$malicious_dir"

ls -l "$dir" > directory-info.new
if [ ! -f directory-info.last ]; then
    echo "First run: scanning..."
    cp directory-info.new directory-info.last
fi
while true; do
    sleep "$interval"
    ls -l "$dir" > directory-info.new

    if ! diff -q directory-info.last directory-info.new > /dev/null; then
        echo "Change detected: scanning..."
        cp directory-info.new directory-info.last
    fi
done


