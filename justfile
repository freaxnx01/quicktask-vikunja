# quicktask-vikunja — common dev tasks (just recipes)
#
# `just` with no args prints the recipe list.
#
# Requires just >= 1.20. Install:
#   Linux:   sudo apt install just  (or: cargo install just)
#   macOS:   brew install just
#   Windows: winget install Casey.Just

set windows-shell := ["pwsh", "-NoLogo", "-NonInteractive", "-Command"]
set dotenv-load

apk := "build/app/outputs/flutter-apk/app-release.apk"

# Show this help (`just` with no args)
default:
    @just --list --unsorted

# Build release APK
[group('build')]
apk:
    ./tool/build.sh apk

# Build Windows release
[group('build')]
windows:
    ./tool/build.sh windows

# Send APK to phone via LocalSend (PHONE_IP=192.168.x.y, builds if missing)
[group('build')]
push:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f "{{apk}}" ]; then
        ./tool/build.sh apk
    fi
    ./tool/push-to-phone.sh

# flutter clean
[group('cleanup')]
clean:
    flutter clean
