#!/usr/bin/env bash
set -Eeuo pipefail

dotfiles="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
timestamp="$(date +%Y%m%d-%H%M%S)"

links=(
	"$HOME/Library/Application Support/Code - Insiders/User/settings.json|$dotfiles/editors/vscode/settings.json"
	"$HOME/Library/Application Support/Code - Insiders/User/keybindings.json|$dotfiles/editors/vscode/keybindings.json"
	"$HOME/.config/ghostty/config.ghostty|$dotfiles/ghostty/config"
	"$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty|$dotfiles/ghostty/cmux/config"
	"$HOME/.config/cmux/cmux.json|$dotfiles/cmux/cmux.json"
	"$HOME/.zshrc|$dotfiles/zsh/.zshrc"
	"$HOME/.p10k.zsh|$dotfiles/zsh/.p10k.zsh"
	"$HOME/.omp/agent/config.yml|$dotfiles/agentic/omp/config.yml"
	"$HOME/.omp/agent/mcp.json|$dotfiles/agentic/omp/mcp.json"
	"$HOME/.omp/agent/lsp.json|$dotfiles/agentic/omp/lsp.json"
	"$HOME/.omp/agent/models.yml|$dotfiles/agentic/omp/models.yml"
	"$HOME/.omp/agent/RULES.md|$dotfiles/agentic/omp/agents/RULES.md"
	"$HOME/.gitconfig|$dotfiles/git/.gitconfig"
	"$HOME/.gitignore_global|$dotfiles/git/.gitignore_global"
)

for entry in "${links[@]}"; do
	IFS='|' read -r link target <<<"$entry"

	if [[ ! -e "$target" ]]; then
		printf '❌ [ERROR] Target does not exist: %s\n' "$target" >&2
		exit 1
	fi

	parent="$(dirname -- "$link")"
	mkdir -p -- "$parent"

	if [[ -L "$link" ]]; then
		current_target="$(readlink -- "$link")"
		if [[ "$current_target" == "$target" ]]; then
			printf '✅ [OK] %s -> %s\n' "$link" "$target"
			continue
		fi

		rm -- "$link"
	elif [[ -e "$link" ]]; then
		backup="$link.backup-$timestamp"
		mv -- "$link" "$backup"
		printf '📦 [BACKUP] %s -> %s\n' "$link" "$backup"
	fi

	ln -s -- "$target" "$link"
	printf '🔗 [LINK] %s -> %s\n' "$link" "$target"
done
