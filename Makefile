.PHONY: build app run clean

APP_NAME := BlackBar
APP_DIR := build/$(APP_NAME).app
BIN := .build/release/$(APP_NAME)

build:
	swift build -c release

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(BIN)" "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(APP_DIR)/Contents/Info.plist"
	chmod +x "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"

run: app
	open "$(APP_DIR)"

clean:
	rm -rf .build build
