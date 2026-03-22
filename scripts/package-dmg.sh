#!/usr/bin/env bash
# Usage: package-dmg.sh <Statdock.app> <output.dmg> <volume name>
# Stages on the boot volume (/tmp): hdiutil + external project disks often hit "Operation not permitted"
# if the image is built directly on a removable volume. Also detach a stale mount with the same volname.
set -euo pipefail
APP="$1"
OUT="$2"
VOLNAME="$3"
MOUNT="/Volumes/${VOLNAME}"
if [[ -d "$MOUNT" ]]; then
	hdiutil detach "$MOUNT" || true
fi
STAGE="$(mktemp -d /tmp/statdock-dmg-stage.XXXXXX)"
TMP_DMG="/tmp/statdock-dmg-$$-${RANDOM}.dmg"
trap 'rm -rf "$STAGE"; rm -f "$TMP_DMG"' EXIT
cp -R "$APP" "$STAGE/"
ln -sf /Applications "$STAGE/Applications"
rm -f "$OUT"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDZO "$TMP_DMG"
cp "$TMP_DMG" "$OUT"
