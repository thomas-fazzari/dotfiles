#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
tools_file="$script_dir/tools.txt"

if [[ ! -f "$tools_file" ]]; then
	printf '[ERROR] tools.txt not found at %s\n' "$tools_file" >&2
	exit 1
fi

installed_tools="$(dotnet tool list --global 2>/dev/null || true)"

while IFS= read -r tool || [[ -n "$tool" ]]; do
	tool="${tool%%#*}"
	tool="${tool#"${tool%%[![:space:]]*}"}"
	tool="${tool%"${tool##*[![:space:]]}"}"

	[[ -z "$tool" ]] && continue

	if printf '%s\n' "$installed_tools" | grep -qE "^${tool}[[:space:]]"; then
		printf '[INFO] Updating dotnet tool: %s\n' "$tool"
		dotnet tool update --global "$tool"
	else
		printf '[INFO] Installing dotnet tool: %s\n' "$tool"
		dotnet tool install --global "$tool"
	fi
done <"$tools_file"
