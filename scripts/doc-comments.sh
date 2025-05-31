#!/usr/bin/env bash

out=$(grep -nr "^--- @" lua)

if [ "$out" ]; then
	last_file=""
	while read -r line; do
		file="$(echo "$line" | cut -d: -f1)"
		if [[ "$file" != "$last_file" ]]; then
			echo "$file:" >&2
			last_file="$file"
		fi
		echo "$line" | awk -F: '{ printf("  line %s: %s\n", $2, $3) }' >&2
	done <<< "$out"
	exit 1
fi
