#!/usr/bin/env bash

# Stack Auth Swift SDK - Run Script
# This script builds and executes the example application

set -e

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "Error: Swift is not installed or not in PATH"
    echo ""
    echo "Please install Swift from: https://swift.org/download/"
    echo ""
    echo "Platform-specific installation:"
    echo "  - macOS: Install Xcode from the App Store"
    echo "  - Linux: sudo apt-get install swiftlang (or equivalent for your distro)"
    echo ""
    exit 1
fi

# Print Swift version
echo "Stack Auth Swift SDK"
echo "===================="
echo ""
swift --version
echo ""

# Build the package
echo "Building package..."
swift build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo ""
    echo "Build failed. Please check the errors above."
    exit 1
fi

echo ""
echo "Build successful!"
echo ""
echo "Running StackAuthExample..."
echo ""

# Run the example with all forwarded arguments
swift run StackAuthExample "$@"

# Exit with the same code as the example
exit $?
