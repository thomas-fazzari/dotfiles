#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
extensions_file="$script_dir/extensions.txt"

if [[ ! -f "$extensions_file" ]]; then
	printf '[ERROR] extensions.txt not found at %s\n' "$extensions_file" >&2
	exit 1
fi

if command -v code-insiders >/dev/null 2>&1; then
	vscode_cmd="code-insiders"
elif command -v code >/dev/null 2>&1; then
	vscode_cmd="code"
else
	printf "[ERROR] Neither 'code-insiders' nor 'code' was found in PATH.\n" >&2
	exit 1
fi

sed 's/#.*//' "$extensions_file" | awk '{$1=$1}; NF' | sort -u |
	while IFS= read -r extension; do
		printf '[INFO] Installing: %s\n' "$extension"
		"$vscode_cmd" --install-extension "$extension"
	done
