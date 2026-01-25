#!/bin/bash
while read repo; do claude plugin marketplace add "$repo"; done < marketplaces.txt
while read plugin; do claude plugin install "$plugin"; done < plugins.txt
