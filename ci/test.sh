#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xeo pipefail

xcodebuild \
    -scheme PocketSVG \
    -destination "platform=iOS Simulator,OS=18.2,name=iPhone 16 Pro" \
    test \
    | xcbeautify

xcodebuild \
    -scheme PocketSVG \
    -destination "platform=iOS Simulator,OS=18.2,name=iPhone 16 Pro" \
    test \
    | xcbeautify
