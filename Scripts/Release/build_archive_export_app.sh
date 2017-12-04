#!/usr/bin/env bash

set -o errexit
set -o nounset

PROJECT_DIR=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$PROJECT_DIR")
BUILD_DIR="$PROJECT_DIR/Build"
INFOPLIST_FILE="Info.plist"
INFOPLIST_FILE_DIR="$BUILD_DIR/$PROJECT_NAME.app/Contents"

mkdir -p "$BUILD_DIR"
rm -rf "$BUILD_DIR"/*

xcodebuild clean -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" -configuration Release -alltargets
xcodebuild archive -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive"
xcodebuild -exportArchive -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" -exportPath "$BUILD_DIR" -exportOptionsPlist "$PROJECT_DIR/Scripts/Release/export_options.plist"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFOPLIST_FILE_DIR/$INFOPLIST_FILE")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFOPLIST_FILE_DIR/$INFOPLIST_FILE")
GIT_SHORT_HASH=$(/usr/libexec/PlistBuddy -c "Print GitShortHash" "$INFOPLIST_FILE_DIR/$INFOPLIST_FILE")

zip -r "$BUILD_DIR/$PROJECT_NAME-v${VERSION}-b${BUILD_NUMBER}.zip" "$BUILD_DIR/$PROJECT_NAME.app"
find "$BUILD_DIR" -mindepth 1 -maxdepth 1 -not -name "*.zip" -not -name "*.app" -print0 | xargs -0 rm -rf

cat > "$BUILD_DIR/version.json" <<EOF
{
  "version": "$VERSION",
  "build_number": "$BUILD_NUMBER",
  "git_short_hash": "$GIT_SHORT_HASH"
}
EOF
