#!/bin/bash

# ---- 1. Validate arguments ----
if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs"
    exit 1
fi

dir="$1"
malicious_dir="$2"
interval="$3"

mkdir -p "$malicious_dir"

# ---- 2. Flagged keywords list (flagged extensions are inside is_malicious) ----
BAD_KEYWORDS="virus|trojan|malware|worm|ransomware"

# ---- 3. Decide whether a file is malicious ----
is_malicious() {
    file="$1"

    case "$file" in
        *.exe|*.bat|*.vbs|*.scr|*.ps1) return 0 ;;
    esac

    if grep -qiE "$BAD_KEYWORDS" "$dir/$file"; then
        return 0
    fi

    return 1
}

# ---- 4. Scan the directory ----
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

# ---- 5. First run ----
ls -l "$dir" > directory-info.new

if [ ! -f directory-info.last ]; then
    scan
    cp directory-info.new directory-info.last
fi

# ---- 6. Main loop ----
while true; do
    sleep "$interval"
    ls -l "$dir" > directory-info.new

    if ! diff -q directory-info.last directory-info.new > /dev/null; then
        scan
        cp directory-info.new directory-info.last
    fi
done
