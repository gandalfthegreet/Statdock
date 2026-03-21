# Statdock — menu bar system monitor (GitHub distribution; not sandboxed in dev bundle)
#
# The .app is written under ./Dist/ so it shows up next to the project in Finder
# (building into /tmp is easy to miss and can be cleared on reboot).
APP_NAME = Statdock
BUILD = .build/release/$(APP_NAME)
APP_DIR = $(CURDIR)/Dist/$(APP_NAME).app
VERSION = $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$(CURDIR)/Info.plist" 2>/dev/null || echo 0.1.0)
DMG = $(CURDIR)/Dist/$(APP_NAME)-$(VERSION).dmg

.PHONY: build release app dmg clean

release:
	swift build -c release

build:
	swift build

app: release
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS"
	cp "$(BUILD)" "$(APP_DIR)/Contents/MacOS/"
	cp Info.plist "$(APP_DIR)/Contents/Info.plist"
	@echo "Built: $(APP_DIR)"
	@echo "Open this folder in Finder, or: open \"$(APP_DIR)\""

# Compressed disk image for hosting (e.g. GitHub Releases). Drag Statdock.app → Applications.
dmg: app
	@set -e; \
	STAGE=$$(mktemp -d); \
	trap 'rm -rf "$$STAGE"' EXIT; \
	cp -R "$(APP_DIR)" "$$STAGE/"; \
	ln -sf /Applications "$$STAGE/Applications"; \
	rm -f "$(DMG)"; \
	hdiutil create -volname "$(APP_NAME) $(VERSION)" -srcfolder "$$STAGE" -ov -format UDZO "$(DMG)"; \
	echo "DMG: $(DMG)"

clean:
	swift package clean
	rm -rf "$(CURDIR)/Dist/$(APP_NAME).app"
	rm -f "$(CURDIR)/Dist/$(APP_NAME)"-*.dmg
