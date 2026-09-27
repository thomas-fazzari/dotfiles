setup:
	INSTALL=1 macos/setup-apps.sh
	editors/vscode/setup-extensions.sh
	dotnet/setup-tools.sh
	rust/setup-tools.sh
	macos/setup-symlinks.sh
	just roslyn-mcp

app-setup:
	macos/setup-apps.sh

vscode:
	editors/vscode/setup-extensions.sh

dotnet:
	dotnet/setup-tools.sh

rust:
	rust/setup-tools.sh

symlinks:
	macos/setup-symlinks.sh

roslyn-mcp:
	curl -fsSL https://raw.githubusercontent.com/thomas-fazzari/roslyn-for-clankers/master/install.sh | bash -s -- --yes
