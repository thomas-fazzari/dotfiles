#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
brewfile="$script_dir/Brewfile"

if ! command -v brew >/dev/null 2>&1; then
	printf '❌ [FAIL] Homebrew not found.\n' >&2
	exit 1
fi

if [[ ! -f "$brewfile" ]]; then
	printf '❌ [FAIL] Brewfile not found: %s\n' "$brewfile" >&2
	exit 1
fi

taps=()
formulae=()
casks=()

while IFS= read -r line || [[ -n "$line" ]]; do
	line="${line%%#*}"
	line="${line#"${line%%[![:space:]]*}"}"
	line="${line%"${line##*[![:space:]]}"}"
	[[ -z "$line" ]] && continue

	if [[ "$line" =~ ^tap[[:space:]]+\"([^\"]+)\" ]]; then
		taps+=("${BASH_REMATCH[1]}")
	elif [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
		formulae+=("${BASH_REMATCH[1]}")
	elif [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
		casks+=("${BASH_REMATCH[1]}")
	fi
done <"$brewfile"

tap_installed() {
	local tap="$1"
	brew tap | grep -Fxq "$tap"
}

formula_installed() {
	local formula="$1"
	brew list --formula "$formula" >/dev/null 2>&1
}

cask_installed() {
	local cask="$1"
	brew list --cask "$cask" >/dev/null 2>&1
}

formula_outdated() {
	local formula="$1"
	[[ -n "$(brew outdated --formula "$formula" 2>/dev/null)" ]]
}

cask_outdated() {
	local cask="$1"
	[[ -n "$(brew outdated --cask "$cask" 2>/dev/null)" ]]
}

if [[ "${INSTALL:-0}" == "1" ]]; then
	printf '🍺 [INFO] Installing/updating Brewfile dependencies.\n'

	for tap in "${taps[@]}"; do
		if tap_installed "$tap"; then
			printf '✅ [OK] tap %s\n' "$tap"
		else
			brew tap "$tap"
		fi
	done

	for formula in "${formulae[@]}"; do
		if ! formula_installed "$formula"; then
			brew install "$formula"
		elif formula_outdated "$formula"; then
			brew upgrade "$formula"
		else
			printf '✅ [OK] brew %s\n' "$formula"
		fi
	done

	for cask in "${casks[@]}"; do
		if ! cask_installed "$cask"; then
			brew install --cask "$cask"
		elif cask_outdated "$cask"; then
			brew upgrade --cask "$cask" || brew reinstall --cask --no-ask "$cask"
		else
			printf '✅ [OK] cask %s\n' "$cask"
		fi
	done

	go install golang.org/x/tools/gopls@latest

	exit 0
fi

missing_taps=()
missing_formulae=()
missing_casks=()
outdated_formulae=()
outdated_casks=()

for tap in "${taps[@]}"; do
	tap_installed "$tap" || missing_taps+=("$tap")
done

for formula in "${formulae[@]}"; do
	if ! formula_installed "$formula"; then
		missing_formulae+=("$formula")
	elif formula_outdated "$formula"; then
		outdated_formulae+=("$formula")
	fi
done

for cask in "${casks[@]}"; do
	if ! cask_installed "$cask"; then
		missing_casks+=("$cask")
	elif cask_outdated "$cask"; then
		outdated_casks+=("$cask")
	fi
done

work_count=$((${#missing_taps[@]} + ${#missing_formulae[@]} + ${#missing_casks[@]} + ${#outdated_formulae[@]} + ${#outdated_casks[@]}))
if ((work_count == 0)); then
	printf '✅ [OK] Brewfile dependencies are already installed and current.\n'
	printf '🧪 [DRY-RUN] Would install golang.org/x/tools/gopls@latest\n'
	exit 0
fi

printf '📦 [INFO] Missing/outdated dependencies: %d\n' "$work_count"
if ((${#missing_taps[@]} > 0)); then
	printf '  taps:\n'
	printf '    %s\n' "${missing_taps[@]}"
fi
if ((${#missing_formulae[@]} > 0)); then
	printf '  formulae:\n'
	printf '    %s\n' "${missing_formulae[@]}"
fi
if ((${#outdated_formulae[@]} > 0)); then
	printf '  outdated formulae:\n'
	printf '    %s\n' "${outdated_formulae[@]}"
fi
if ((${#missing_casks[@]} > 0)); then
	printf '  casks:\n'
	printf '    %s\n' "${missing_casks[@]}"
fi
if ((${#outdated_casks[@]} > 0)); then
	printf '  outdated casks:\n'
	printf '    %s\n' "${outdated_casks[@]}"
fi

printf '🧪 [DRY-RUN] Would install golang.org/x/tools/gopls@latest\n'

printf '\n🧪 [DRY-RUN] No packages installed. Run this when ready:\n'
printf '  INSTALL=1 make app-setup\n'
