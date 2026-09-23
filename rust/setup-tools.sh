#!/usr/bin/env bash
set -Eeuo pipefail

if ! rustup show active-toolchain >/dev/null 2>&1; then
	rustup toolchain install stable --profile minimal
	rustup default stable
fi

rustup component add rust-analyzer rust-src rustfmt clippy llvm-tools-preview

tools=(cargo-deny cargo-llvm-cov cargo-machete cargo-nextest)

for tool in "${tools[@]}"; do
	if command -v "$tool" >/dev/null 2>&1; then
		printf 'Already installed: %s\n' "$tool"
	else
		cargo install --locked "$tool"
	fi
done
