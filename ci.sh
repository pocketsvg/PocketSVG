## This file is part of the PocketSVG package.
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
## This script builds the iOS and macOS frameworks and demos, and
# runs the tests on iOS. Our CI system requires that this script
# run successfully. It is called via .travis.yml and you can see
# the results over at https://travis-ci.org/pocketsvg/PocketSVG
#
# You can run this script locally before pushing your changes to
# check the build and tests run as they should.

# print every command:
set -x
# stop execution if an error occurs:
set -eo pipefail

DESTINATION="platform=iOS Simulator,name=iPhone 11,OS=13.0"

## build iOS framework:
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme "PocketSVG (iOS)" \
  -destination "$DESTINATION" \
  clean build | xcpretty

## build macOS framework:
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme "PocketSVG (Mac)" \
  -destination "arch=x86_64" \
  clean build | xcpretty

## build iOS demo:
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "$DESTINATION" \
  -scheme Demo-iOS \
  clean build | xcpretty

## build macOS demo:
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "arch=x86_64" \
  -scheme Demo-macOS \
  clean build | xcpretty

## run tests:
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme PocketSVGTests \
  -destination "$DESTINATION" \
  test | xcpretty
