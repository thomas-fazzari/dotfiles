#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
extensions_file="$script_dir/extensions.json"
vscode_cmd=""

info() {
	printf '[INFO] %s\n' "$*"
}

warn() {
	printf '[WARN] %s\n' "$*" >&2
}

error() {
	printf '[ERROR] %s\n' "$*" >&2
}

contains_line() {
	local haystack="$1"
	local needle="$2"

	[[ $'\n'"$haystack"$'\n' == *$'\n'"$needle"$'\n'* ]]
}

detect_vscode_cmd() {
	if command -v code-insiders >/dev/null 2>&1; then
		vscode_cmd="code-insiders"
		return 0
	fi

	if command -v code >/dev/null 2>&1; then
		vscode_cmd="code"
		return 0
	fi

	error "Neither 'code-insiders' nor 'code' was found in PATH."
	return 1
}

read_extensions() {
	if command -v jq >/dev/null 2>&1; then
		jq -r '.recommendations[]? // empty' "$extensions_file"
		return 0
	fi

	if command -v python3 >/dev/null 2>&1; then
		python3 - "$extensions_file" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)

for ext in data.get("recommendations", []):
    if isinstance(ext, str) and ext.strip():
        print(ext.strip())
PY
		return 0
	fi

	if command -v node >/dev/null 2>&1; then
		node -e '
const fs = require("fs");
const file = process.argv[1];
const data = JSON.parse(fs.readFileSync(file, "utf8"));
for (const ext of data.recommendations || []) {
  if (typeof ext === "string" && ext.trim()) {
    process.stdout.write(ext.trim() + "\n");
  }
}
' "$extensions_file"
		return 0
	fi

	error "Need one of: jq, python3, or node to read $extensions_file"
	return 1
}

main() {
	local installed_extensions=""
	local seen_extensions=""
	local extension=""
	local installed_count=0
	local already_count=0
	local failed_count=0
	local -a extensions=()

	if [[ ! -f "$extensions_file" ]]; then
		error "extensions.json not found at $extensions_file"
		exit 1
	fi

	detect_vscode_cmd

	while IFS= read -r extension; do
		[[ -z "$extension" ]] && continue
		extensions+=("$extension")
	done < <(read_extensions)

	if [[ "${#extensions[@]}" -eq 0 ]]; then
		error "No extensions found in $extensions_file"
		exit 1
	fi

	installed_extensions="$("$vscode_cmd" --list-extensions 2>/dev/null || true)"

	printf '\n'
	info "Found ${#extensions[@]} extensions"
	printf '\n'

	for extension in "${extensions[@]}"; do
		[[ -z "$extension" ]] && continue

		if contains_line "$seen_extensions" "$extension"; then
			continue
		fi
		seen_extensions+=$'\n'"$extension"

		if contains_line "$installed_extensions" "$extension"; then
			info "Already installed: $extension"
			((already_count++))
			continue
		fi

		info "Installing: $extension"
		if "$vscode_cmd" --install-extension "$extension" >/dev/null 2>&1; then
			installed_extensions+=$'\n'"$extension"
			((installed_count++))
		else
			warn "Failed to install: $extension"
			((failed_count++))
		fi
	done

	printf '\n'
	printf '================================\n'
	printf 'Extension install complete\n'
	printf 'Newly installed: %d\n' "$installed_count"
	printf 'Already installed: %d\n' "$already_count"
	printf 'Failed: %d\n' "$failed_count"
	printf '================================\n'

	if [[ "$failed_count" -gt 0 ]]; then
		exit 1
	fi
}

main "$@"
