#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
extensions_file="$script_dir/extensions.txt"

if [[ ! -f "$extensions_file" ]]; then
	printf '❌ [ERROR] extensions.txt not found at %s\n' "$extensions_file" >&2
	exit 1
fi

if ! command -v code-insiders >/dev/null 2>&1; then
	printf "❌ [ERROR] 'code-insiders' was not found in PATH.\n" >&2
	exit 1
fi

vscode_cmd="code-insiders"

failed_extensions=()
while IFS= read -r line || [[ -n "$line" ]]; do
	extension="${line%%#*}"
	extension="${extension#"${extension%%[![:space:]]*}"}"
	extension="${extension%"${extension##*[![:space:]]}"}"
	[[ -z "$extension" ]] && continue

	printf '📦 [INFO] Installing/updating: %s\n' "$extension"
	if ! "$vscode_cmd" --install-extension "$extension" --force; then
		printf '⚠️ [WARN] Failed to install: %s\n' "$extension" >&2
		failed_extensions+=("$extension")
	fi
done <"$extensions_file"

if ((${#failed_extensions[@]} > 0)); then
	printf '❌ [ERROR] Failed to install %d extension(s):\n' "${#failed_extensions[@]}" >&2
	printf '  - %s\n' "${failed_extensions[@]}" >&2
	exit 1
fi
