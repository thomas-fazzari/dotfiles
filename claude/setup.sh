#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install marketplaces
while IFS= read -r repo; do
  [[ -n "$repo" ]] && claude plugin marketplace add "$repo"
done < "$SCRIPT_DIR/marketplaces.txt"

# Install plugins
while IFS= read -r plugin; do
  [[ -n "$plugin" ]] && claude plugin install "$plugin"
done < "$SCRIPT_DIR/plugins.txt"

echo "Claude plugins installed!"
