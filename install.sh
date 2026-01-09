#!/bin/bash

set -e

echo "Dotfiles Setup"
echo ""

DOTFILES_DIR="$HOME/Dev/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

echo "> Creating symlinks..."
echo ""

# Git
echo "> Configuring Git..."
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

# Zsh
echo "> Configuring Zsh..."
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

echo ""
echo "Installation Complete!"
echo ""
echo "Symlinks created:"
echo "  ~/.gitconfig -> $DOTFILES_DIR/git/.gitconfig"
echo "  ~/.gitignore_global -> $DOTFILES_DIR/git/.gitignore_global"
echo "  ~/.zshrc -> $DOTFILES_DIR/zsh/.zshrc"
echo ""
echo "Install VSCode extensions? (Y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    "$DOTFILES_DIR/editors/vscode/setup-extensions.sh"
fi
echo ""
