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
    -destination "platform=iOS Simulator,name=iPhone 15" \
    test \
    | xcbeautify

xcodebuild \
    -scheme PocketSVG \
    -destination "platform=iOS Simulator,name=iPhone 15" \
    test \
    | xcbeautify
