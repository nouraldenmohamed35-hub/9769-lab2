#!/bin/bash

# Validate arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir"
    exit 1
fi

dir="$1"
malicious_dir="$2"
whitelist="$(cd "$(dirname "$0")" && pwd)/whitelist.txt"

# Nothing to review if quarantine is empty or missing
if [ -z "$(ls -A "$malicious_dir" 2>/dev/null)" ]; then
    echo "No malicious files to review."
    exit 0
fi

while true; do
    # Load quarantined file names into an array
    mapfile -t files < <(ls -A "$malicious_dir")

    # Stop when everything has been reviewed
    if [ ${#files[@]} -eq 0 ]; then
        exit 0
    fi

    echo "Choose a file:"
    for i in "${!files[@]}"; do
        echo "$((i+1)): ${files[$i]}"
    done

    # Stop cleanly if the input ends
    read -r num || exit 0

    # Validate the number
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#files[@]}" ]; then
        echo "Invalid choice."
        continue
    fi

    file="${files[$((num-1))]}"

    echo "For $file:"
    echo "1: Restore this file back into dir (it was a false positive)"
    echo "2: Permanently delete this file from malicious_dir (it was genuinely malicious)"
    echo "3: Go back"
    read -r opt || exit 0

    case "$opt" in
        1)
            mv "$malicious_dir/$file" "$dir/$file"
            echo "$file" >> "$whitelist"
            echo "Restored $file to $dir."
            ;;
        2)
            rm "$malicious_dir/$file"
            echo "$file permanently deleted."
            ;;
        3)
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
