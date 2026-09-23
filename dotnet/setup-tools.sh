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

	printf '🔄 [INFO] Installing/updating dotnet tool: %s\n' "$tool"
	if [[ "$tool" == "roslyn-language-server" ]]; then
		if ! dotnet tool update --global "$tool" --prerelease; then
			dotnet tool install --global "$tool" --prerelease
		fi
	elif ! dotnet tool update --global "$tool"; then
		dotnet tool install --global "$tool"
	fi
done <"$tools_file"
