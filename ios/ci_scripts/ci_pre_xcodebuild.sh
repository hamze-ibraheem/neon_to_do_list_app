#!/bin/sh

# Xcode Cloud Pre-Xcodebuild Script
# Automatically bumps the build number using Xcode Cloud's CI_BUILD_NUMBER so TestFlight uploads never conflict.

set -e

echo "=== [Xcode Cloud] Pre-Xcodebuild Script Running ==="

BUILD_NUMBER=${CI_BUILD_NUMBER:-"1"}
echo "Using CI Build Number: $BUILD_NUMBER"

# Locate Info.plist files and update CFBundleVersion
find . -name "Info.plist" -not -path "*/Pods/*" -not -path "*/DerivedData/*" | while read plist_file; do
    if [ -f "$plist_file" ]; then
        echo "Updating build version in $plist_file to $BUILD_NUMBER"
        plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$plist_file" 2>/dev/null || true
    fi
done

echo "=== [Xcode Cloud] Pre-Xcodebuild Setup Completed Successfully ==="
