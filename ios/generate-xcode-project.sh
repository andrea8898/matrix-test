#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen non è installato. Su macOS esegui: brew install xcodegen"
  exit 1
fi

xcodegen generate
echo "Creato MatrixTest.xcodeproj. Aprilo in Xcode, scegli il Team di firma e un iPhone fisico."
