#!/bin/sh

# Xcode Cloud Post-Clone Script
# Executed by Xcode Cloud runners after cloning the repository.

set -e

echo "=== [Xcode Cloud] Post-Clone Initializing for Neon App ==="
echo "Workflow: $CI_WORKFLOW"
echo "Product: $CI_PRODUCT"
echo "Build Number: $CI_BUILD_NUMBER"
echo "Branch: $CI_BRANCH"
echo "Commit: $CI_COMMIT"

# Verify Xcode version
xcodebuild -version

# Run pod install if CocoaPods is configured
if [ -f "ios/Podfile" ]; then
    echo "=== Running pod install for CocoaPods ==="
    cd ios && pod install && cd ..
elif [ -f "Podfile" ]; then
    echo "=== Running pod install for CocoaPods ==="
    pod install
fi

echo "=== [Xcode Cloud] Post-Clone Complete ==="
