if [[ -d /opt/homebrew/opt/rustup/bin ]]; then
	typeset -U path
	path=(/opt/homebrew/opt/rustup/bin $path)
fi
