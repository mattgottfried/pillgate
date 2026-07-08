#!/bin/sh
set -e

# Xcode Cloud runs this after cloning, before it resolves the Xcode project.
# The .xcodeproj is not committed to the repo — generate it with XcodeGen.
brew install xcodegen

cd "$CI_PRIMARY_REPOSITORY_PATH/IoniqOS"
xcodegen generate
