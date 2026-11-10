#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xeo pipefail

# Select an installed iPhone rather than relying on a particular device name.
simulator_id=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if ".iOS-" in runtime:
        for device in devices:
            if device["name"].startswith("iPhone"):
                print(device["udid"])
                sys.exit(0)
sys.exit("No available iPhone simulator")
')

xcodebuild \
    -scheme PocketSVG \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    test \
    | xcbeautify
