#!/usr/bin/env bash

find . -name '*.ots' -type f -print0 | while IFS= read -r -d '' file; do
    echo -e "\033[1;34m${file}:\033[0m"
    ots upgrade "$file"
    sleep 0.1
    echo
done
