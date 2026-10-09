#!/bin/bash

# Single-run version of antivirusd.sh, meant to be started by cron
if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir"
    exit 1
fi

# Use absolute paths because cron runs from a different working directory
script_dir="$(cd "$(dirname "$0")" && pwd)"
dir="$(realpath "$1")"
malicious_dir="$(realpath -m "$2")"
last="$script_dir/directory-info.last"
new="$script_dir/directory-info.new"
whitelist="$script_dir/whitelist.txt"

mkdir -p "$malicious_dir"

BAD_KEYWORDS="virus|trojan|malware|worm|ransomware"

is_malicious() {
    file="$1"

    # Skip files that were restored by the user (whitelist)
    if [ -f "$whitelist" ] && grep -qxF "$file" "$whitelist"; then
        return 1
    fi

    case "$file" in
        *.exe|*.bat|*.vbs|*.scr|*.ps1) return 0 ;;
    esac

    if grep -qiE "$BAD_KEYWORDS" "$dir/$file"; then
        return 0
    fi

    return 1
}

scan() {
    for path in "$dir"/*; do
        [ -f "$path" ] || continue
        file=$(basename "$path")

        if is_malicious "$file"; then
            echo "$file is malicious and it is DELETED"
            cp "$path" "$malicious_dir/$file"
            rm "$path"
        fi
    done
}

ls -l "$dir" > "$new"

# Scan on the first run (no .last file) or when the listing changed
if [ ! -f "$last" ] || ! diff -q "$last" "$new" > /dev/null; then
    scan
    ls -l "$dir" > "$last"
fi
