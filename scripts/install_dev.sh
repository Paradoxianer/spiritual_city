#!/usr/bin/env bash
# Builds the dev variant ("Spiritual City Dev", app id …spiritual_city.dev)
# and installs it on a phone via adb – next to the Play Store version.
#
#   scripts/install_dev.sh [adb-serial]
set -euo pipefail
cd "$(dirname "$0")/.."
SC_DEV=1 flutter build apk --release --split-per-abi --target-platform android-arm64
adb ${1:+-s "$1"} install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
