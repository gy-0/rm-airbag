.PHONY: lint test package install uninstall

lint:
	zsh -n bin/rm-airbag scripts/install.sh scripts/uninstall.sh scripts/package.sh tests/fake-trash.zsh tests/run.zsh

test: lint
	zsh tests/run.zsh

package: test
	zsh scripts/package.sh

install:
	zsh scripts/install.sh

uninstall:
	zsh scripts/uninstall.sh

