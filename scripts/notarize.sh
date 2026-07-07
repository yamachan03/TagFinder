#!/bin/bash
# Archive, sign with Developer ID, notarize, staple, and verify TagFinder.
#
# Prerequisites (one-time):
#   1. A "Developer ID Application" certificate in the keychain
#      (Xcode > Settings > Accounts > Manage Certificates... > + )
#   2. notarytool credentials stored as the profile named below:
#      xcrun notarytool store-credentials "tagfinder-notary" \
#        --apple-id <apple-id> --team-id 7JSPUB92B6 --password <app-specific-password>
#
# Usage: ./scripts/notarize.sh
# Output: build/export/TagFinder.app (signed, notarized, stapled)

set -euo pipefail
cd "$(dirname "$0")/.."

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
PROFILE="tagfinder-notary"
BUILD_DIR="build"

echo "==> 1/6 Archiving (Release)"
rm -rf "$BUILD_DIR"
xcodebuild -project TagFinder.xcodeproj -scheme TagFinder -configuration Release \
  archive -archivePath "$BUILD_DIR/TagFinder.xcarchive" -quiet

echo "==> 2/6 Exporting with Developer ID signing"
cat > "$BUILD_DIR/ExportOptions.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>7JSPUB92B6</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath "$BUILD_DIR/TagFinder.xcarchive" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -exportPath "$BUILD_DIR/export" -quiet

APP="$BUILD_DIR/export/TagFinder.app"

echo "==> 3/6 Zipping for submission"
ditto -c -k --keepParent "$APP" "$BUILD_DIR/TagFinder.zip"

echo "==> 4/6 Submitting to Apple notary service (waits for the result)"
xcrun notarytool submit "$BUILD_DIR/TagFinder.zip" \
  --keychain-profile "$PROFILE" --wait

echo "==> 5/6 Stapling the notarization ticket"
xcrun stapler staple "$APP"

echo "==> 6/6 Verifying"
spctl -a -vv "$APP"
xcrun stapler validate "$APP"

echo
echo "Done: $APP"
echo "Install with: sudo rm -rf /Applications/TagFinder.app && ditto '$APP' /Applications/TagFinder.app"
echo "Note: the new signature requires re-granting Full Disk Access once."
