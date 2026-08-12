#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
tools_file="$script_dir/tools.txt"

if [[ ! -f "$tools_file" ]]; then
	printf '❌ [ERROR] tools.txt not found at %s\n' "$tools_file" >&2
	exit 1
fi

while IFS= read -r tool || [[ -n "$tool" ]]; do
	tool="${tool%%#*}"
	tool="${tool#"${tool%%[![:space:]]*}"}"
	tool="${tool%"${tool##*[![:space:]]}"}"

	[[ -z "$tool" ]] && continue

	tool_args=()
	[[ "$tool" == "roslyn-language-server" ]] && tool_args+=(--prerelease)

	printf '🔄 [INFO] Installing/updating dotnet tool: %s\n' "$tool"
	if ! dotnet tool update --global "$tool" "${tool_args[@]}"; then
		dotnet tool install --global "$tool" "${tool_args[@]}"
	fi
done <"$tools_file"
