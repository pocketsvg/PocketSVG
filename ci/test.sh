#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xe

xcodebuild \
    -scheme PocketSVGTests \
    -destination "platform=iOS Simulator,name=iPhone 11 Pro" \
    test \
    | xcpretty

xcodebuild \
    -scheme PocketSVGTests \
    -destination 'platform=macOS,arch=x86_64' \
    test \
    | xcpretty
