#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.json"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
  echo "Error: extensions.json not found at $EXTENSIONS_FILE"
  exit 1
fi

# Detect VS Code command

if command -v code-insiders &>/dev/null; then
  VSCODE_CMD="code-insiders"
elif command -v code &>/dev/null; then
  VSCODE_CMD="code"
else
  echo "Error: Neither 'code-insiders' nor 'code' command found."
  exit 1
fi

# Ensure jq is installed

if ! command -v jq &>/dev/null; then
  echo "Installing jq..."
  if command -v brew &>/dev/null; then
    brew install jq
  elif command -v choco &>/dev/null; then
    choco install jq -y
  else
    echo "Error: Could not install jq."
    exit 1
  fi
fi

# Extract and install extensions

extensions=()
while IFS= read -r extension; do
  extensions+=("$extension")
done < <(jq -r '.recommendations[]' "$EXTENSIONS_FILE")

if [[ ${#extensions[@]} -eq 0 ]]; then
  echo "Error: No extensions found in $EXTENSIONS_FILE"
  exit 1
fi

echo ""
echo "Found ${#extensions[@]} extensions"
echo ""

success_count=0
failed_count=0

for extension in "${extensions[@]}"; do
  [[ -z "$extension" ]] && continue

  echo "Installing: $extension"
  if $VSCODE_CMD --install-extension "$extension" 2>&1 | grep -q "successfully installed\|already installed"; then
    ((success_count++))
  else
    echo "  Warning: Failed to install $extension"
    ((failed_count++))
  fi
done

echo ""
echo "================================"
echo "Installation complete!"
echo "Successfully installed: $success_count"
echo "Failed: $failed_count"
echo "================================"
