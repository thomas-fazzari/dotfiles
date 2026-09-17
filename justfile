setup:
	INSTALL=1 macos/setup-apps.sh
	editors/vscode/setup-extensions.sh
	dotnet/setup-tools.sh
	macos/setup-symlinks.sh

app-setup:
	macos/setup-apps.sh

vscode:
	editors/vscode/setup-extensions.sh

dotnet:
	dotnet/setup-tools.sh

symlinks:
	macos/setup-symlinks.sh
