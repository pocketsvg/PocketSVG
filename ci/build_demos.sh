#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xeo pipefail

# useful for development:
rm -rf .build/
rm -rf derived_data/

IOS_DESTINATION="platform=iOS Simulator,name=iPhone 15"

echo "Build iOS demo"
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "$IOS_DESTINATION" \
  -scheme Demo-iOS \
  -derivedDataPath derived_data \
  'OTHER_LDFLAGS=$(inherited) -lxml2' \
  clean \
  build \
  | xcbeautify

echo "Build macOS demo"
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "arch=x86_64" \
  -derivedDataPath derived_data \
  -scheme Demo-macOS \
  'OTHER_LDFLAGS=$(inherited) -lxml2' \
  clean \
  build \
  | xcbeautify
