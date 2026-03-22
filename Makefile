# Statdock — menu bar system monitor (GitHub distribution; not sandboxed in dev bundle)
#
# The .app is written under ./Dist/ so it shows up next to the project in Finder
# (building into /tmp is easy to miss and can be cleared on reboot).
APP_NAME = Statdock
BUILD = .build/release/$(APP_NAME)
APP_DIR = $(CURDIR)/Dist/$(APP_NAME).app
VERSION = $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$(CURDIR)/Info.plist" 2>/dev/null || echo 0.1.0)
DMG = $(CURDIR)/Dist/$(APP_NAME)-$(VERSION).dmg
ENTITLEMENTS = $(CURDIR)/Statdock.entitlements
PACKAGE_DMG = $(CURDIR)/scripts/package-dmg.sh
APP_ICON = $(CURDIR)/Resources/AppIcon.icns

.PHONY: build release assemble-app app dmg dist clean

release:
	swift build -c release

build:
	swift build

# Copy binary + Info.plist (unsigned)
assemble-app: release
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(BUILD)" "$(APP_DIR)/Contents/MacOS/"
	cp Info.plist "$(APP_DIR)/Contents/Info.plist"
	cp "$(APP_ICON)" "$(APP_DIR)/Contents/Resources/AppIcon.icns"

# Local dev: ad-hoc signed .app (Gatekeeper may still prompt on quarantined copies)
app: assemble-app
	codesign --force --deep --sign - "$(APP_DIR)"
	@echo "Built: $(APP_DIR)"
	@echo "Open this folder in Finder, or: open \"$(APP_DIR)\""

# Dev DMG (ad-hoc app inside). For downloads that open without warnings, use `make dist`.
dmg: app
	chmod +x "$(PACKAGE_DMG)"
	"$(PACKAGE_DMG)" "$(APP_DIR)" "$(DMG)" "$(APP_NAME) $(VERSION)"
	@echo "DMG (not notarized): $(DMG)"

# Release DMG: Developer ID + hardened runtime + notarize + staple (requires Apple Developer Program).
#   export CODESIGN_IDENTITY='Developer ID Application: …'
#   export NOTARY_PROFILE=statdock-notary
# See DISTRIBUTION.md
dist: assemble-app
ifndef CODESIGN_IDENTITY
	$(error CODESIGN_IDENTITY is not set. Export your "Developer ID Application" identity. See DISTRIBUTION.md)
endif
ifndef NOTARY_PROFILE
	$(error NOTARY_PROFILE is not set. Run: xcrun notarytool store-credentials … See DISTRIBUTION.md)
endif
	codesign --force --options runtime --sign "$(CODESIGN_IDENTITY)" --entitlements "$(ENTITLEMENTS)" --deep "$(APP_DIR)"
	codesign --verify --verbose=4 "$(APP_DIR)"
	chmod +x "$(PACKAGE_DMG)"
	"$(PACKAGE_DMG)" "$(APP_DIR)" "$(DMG)" "$(APP_NAME) $(VERSION)"
	xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(DMG)"
	xcrun stapler validate "$(DMG)"
	@echo "Release DMG (signed + notarized + stapled): $(DMG)"

clean:
	swift package clean
	rm -rf "$(CURDIR)/Dist/$(APP_NAME).app"
	rm -f "$(CURDIR)/Dist/$(APP_NAME)"-*.dmg
