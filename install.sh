#!/bin/bash

set -e

DOTFILES_DIR="$HOME/Dev/dotfiles"

echo "Dotfiles Setup"
echo ""

if [[ ! -d "$DOTFILES_DIR" ]]; then
	echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
	exit 1
fi

# --- Symlinks ---

echo "Creating symlinks..."
echo ""

# Git
echo "Configuring Git..."
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

# Zsh
echo "Configuring Zsh..."
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# Ghostty
echo "Configuring Ghostty..."
if [[ "$OSTYPE" == "darwin"* ]]; then
	GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
	mkdir -p "$GHOSTTY_DIR"
	ln -sf "$DOTFILES_DIR/terminal/ghostty/config" "$GHOSTTY_DIR/config"
fi

# IdeaVim (JetBrains IDEs)
echo "Configuring IdeaVim..."
ln -sf "$DOTFILES_DIR/editors/ideavim/.ideavimrc" "$HOME/.ideavimrc"

# VS Code
echo "Configuring VS Code..."

if [[ "$OSTYPE" == "darwin"* ]]; then
	VSCODE_USER_DIR="$HOME/Library/Application Support/Code - Insiders/User"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
	VSCODE_USER_DIR="$APPDATA/Code - Insiders/User"
fi

if [[ -n "$VSCODE_USER_DIR" && -d "$VSCODE_USER_DIR" ]]; then
	ln -sf "$DOTFILES_DIR/editors/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
	echo "VS Code settings linked!"

	echo ""
	read -rp "Install VSCode extensions? (y/n) " response
	if [[ "$response" =~ ^[yY]$ ]]; then
		"$DOTFILES_DIR/editors/vscode/setup-extensions.sh"
	fi
else
	echo "VS Code not found, skipping settings"
fi

# Summary
echo ""
echo "Installation Complete!"
echo ""
echo "Symlinks created:"
echo "  ~/.gitconfig -> $DOTFILES_DIR/git/.gitconfig"
echo "  ~/.gitignore_global -> $DOTFILES_DIR/git/.gitignore_global"
echo "  ~/.zshrc -> $DOTFILES_DIR/zsh/.zshrc"
echo "  ~/.ideavimrc -> $DOTFILES_DIR/editors/ideavim/.ideavimrc"

if [[ -n "$GHOSTTY_DIR" ]]; then
	echo "  $GHOSTTY_DIR/config -> $DOTFILES_DIR/terminal/ghostty/config"
fi

if [[ -n "$VSCODE_USER_DIR" && -d "$VSCODE_USER_DIR" ]]; then
	echo "  $VSCODE_USER_DIR/settings.json -> $DOTFILES_DIR/editors/vscode/settings.json"
fi
