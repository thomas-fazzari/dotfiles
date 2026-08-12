.PHONY: setup app-setup vscode dotnet omp symlinks

setup:
	INSTALL=1 macos/setup-apps.sh
	editors/vscode/setup-extensions.sh
	dotnet/setup-tools.sh
	$(MAKE) omp
	macos/setup-symlinks.sh

app-setup:
	macos/setup-apps.sh

vscode:
	editors/vscode/setup-extensions.sh

dotnet:
	dotnet/setup-tools.sh

omp:
	curl -fsSL https://raw.githubusercontent.com/thomas-fazzari/mnemopi-audit/master/install.sh | bash
	omp plugin install context-mode

symlinks:
	macos/setup-symlinks.sh
