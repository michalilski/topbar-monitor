.PHONY: build test app run install uninstall clean

build:
	swift build

test:
	swift test

app:
	./scripts/build-app.sh

run: app
	open build/TopbarMonitor.app

install:
	./scripts/install.sh

uninstall:
	./scripts/uninstall.sh

clean:
	rm -rf .build build
