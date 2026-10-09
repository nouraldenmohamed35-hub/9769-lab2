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
        echo "No malicious files to review."
        exit 0
    fi

    echo "Files in quarantine:"
    for i in "${!files[@]}"; do
        echo "$((i+1))) ${files[$i]}"
    done

    read -p "Pick a file number: " num

    # Validate the number
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#files[@]}" ]; then
        echo "Invalid choice."
        continue
    fi

    file="${files[$((num-1))]}"

    echo "Selected: $file"
    echo "1) Restore (false positive)"
    echo "2) Delete permanently (malicious)"
    echo "3) Leave as is"
    read -p "Choose an option: " opt

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
