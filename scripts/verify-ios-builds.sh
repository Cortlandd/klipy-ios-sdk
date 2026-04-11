#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
destination="generic/platform=iOS Simulator"

run_build() {
  local description="$1"
  shift

  echo
  echo "==> $description"
  (cd "$repo_root" && xcodebuild build "$@" -destination "$destination" -skipPackagePluginValidation -skipMacroValidation)
}

run_build "Building the Swift package" -scheme KlipySDK-Package
run_build "Building the UIKit example app" -workspace KlipySDK.xcworkspace -scheme KlipyChatUIKit
run_build "Building the TCA example app" -workspace KlipySDK.xcworkspace -scheme KlipyChatTCA
