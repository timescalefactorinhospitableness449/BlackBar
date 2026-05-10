.PHONY: build app run ci release clean

APP_NAME := BlackBar

build:
	swift build -c release

app: build
	SKIP_BUILD=1 ./Scripts/package_app.sh release
	rm -rf "build/$(APP_NAME).app"
	mkdir -p build
	APP_DIR="$$(find .build -path "*/release/$(APP_NAME).app" -type d | head -n 1)"; \
	test -n "$$APP_DIR"; \
	cp -R "$$APP_DIR" "build/$(APP_NAME).app"

run: app
	open "build/$(APP_NAME).app"

ci:
	swift package resolve
	swift build -c release
	$(MAKE) app

release:
	./Scripts/release.sh

clean:
	rm -rf .build build *.zip *.dSYM
