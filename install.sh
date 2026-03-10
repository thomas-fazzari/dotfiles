#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
dotfiles_dir="$script_dir"

linked_paths=()

info() {
	printf '[INFO] %s\n' "$*"
}

warn() {
	printf '[WARN] %s\n' "$*" >&2
}

error() {
	printf '[ERROR] %s\n' "$*" >&2
}

link_file() {
	local source_path="$1"
	local target_path="$2"
	local required="${3:-false}"

	if [[ ! -e "$source_path" ]]; then
		if [[ "$required" == "true" ]]; then
			error "Missing required file: $source_path"
			exit 1
		fi

		return 0
	fi

	mkdir -p "$(dirname "$target_path")"
	ln -sfn "$source_path" "$target_path"
	linked_paths+=("$target_path -> $source_path")
}

detect_vscode_user_dir() {
	local candidates=()
	local candidate=""

	case "$OSTYPE" in
	darwin*)
		candidates=(
			"$HOME/Library/Application Support/Code - Insiders/User"
			"$HOME/Library/Application Support/Code/User"
		)
		;;
	msys* | cygwin* | win32)
		if [[ -n "${APPDATA:-}" ]]; then
			candidates=(
				"$APPDATA/Code - Insiders/User"
				"$APPDATA/Code/User"
			)
		fi
		;;
	esac

	for candidate in "${candidates[@]}"; do
		if [[ -d "$candidate" ]]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done

	return 1
}

maybe_install_vscode_extensions() {
	local setup_script="$dotfiles_dir/editors/vscode/setup-extensions.sh"
	local response=""

	if [[ ! -f "$setup_script" ]]; then
		warn "VS Code extension setup script not found: $setup_script"
		return 0
	fi

	if [[ ! -t 0 ]]; then
		info "Non-interactive shell detected. Skipping VS Code extension prompt."
		return 0
	fi

	printf '\n'
	read -r -p "Install VS Code extensions? (y/n) " response
	if [[ "$response" =~ ^[Yy]$ ]]; then
		bash "$setup_script"
	fi
}

print_summary() {
	local entry=""

	printf '\nInstallation complete!\n'
	if [[ "${#linked_paths[@]}" -eq 0 ]]; then
		info "No symlinks were created."
		return 0
	fi

	printf '\nSymlinks created:\n'
	for entry in "${linked_paths[@]}"; do
		printf '  %s\n' "$entry"
	done
}

main() {
	local vscode_user_dir=""

	info "Dotfiles setup"

	if [[ ! -d "$dotfiles_dir" ]]; then
		error "Dotfiles directory not found at $dotfiles_dir"
		exit 1
	fi

	printf '\n'
	info "Creating symlinks..."

	info "Configuring Git..."
	link_file "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig" true
	link_file "$dotfiles_dir/git/.gitignore_global" "$HOME/.gitignore_global" true

	info "Configuring Zsh..."
	link_file "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc" true

	if [[ "$OSTYPE" == darwin* ]]; then
		info "Configuring Ghostty..."
		link_file \
			"$dotfiles_dir/terminal/ghostty/config" \
			"$HOME/Library/Application Support/com.mitchellh.ghostty/config"
	fi

	info "Configuring VS Code..."
	if vscode_user_dir="$(detect_vscode_user_dir)"; then
		link_file "$dotfiles_dir/editors/vscode/settings.json" "$vscode_user_dir/settings.json" true

		if [[ -f "$dotfiles_dir/editors/vscode/keybindings.json" ]]; then
			link_file "$dotfiles_dir/editors/vscode/keybindings.json" "$vscode_user_dir/keybindings.json"
		fi

		maybe_install_vscode_extensions
	else
		warn "VS Code user directory not found. Skipping settings link."
	fi

	print_summary
}

main "$@"
