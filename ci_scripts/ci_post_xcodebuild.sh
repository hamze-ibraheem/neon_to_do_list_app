#!/bin/sh

# Xcode Cloud Post-Xcodebuild Script
# Executed after the archive/export step completes.

set -e

echo "=== [Xcode Cloud] Post-Xcodebuild Archive Finished ==="
if [ -n "$CI_ARCHIVE_PATH" ]; then
    echo "Archive located at: $CI_ARCHIVE_PATH"
fi
echo "Ready for TestFlight automatic distribution!"
