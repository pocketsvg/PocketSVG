## This file is part of the PocketSVG package.
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
## This script builds the Swift Package, the iOS and macOS demos,
# and runs the tests on iOS. Our CI system requires that this script
# run successfully. It is called via .travis.yml and you can see
# the results over at https://travis-ci.org/pocketsvg/PocketSVG
#
# You can run this script locally before pushing your changes to
# check the build and tests run as they should.

# stop execution if an error occurs:
set -eo pipefail

# useful for development:
rm -rf .build/
rm -rf derived_data/

IOS_DESTINATION="platform=iOS Simulator,name=iPhone 11"

echo "Build iOS demo"
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "$IOS_DESTINATION" \
  -scheme Demo-iOS \
  -derivedDataPath derived_data \
  clean build | xcpretty

echo "Build macOS demo"
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "arch=x86_64" \
  -derivedDataPath derived_data \
  -scheme Demo-macOS \
  clean build | xcpretty

echo "Run unit tests"
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "$IOS_DESTINATION" \
  -scheme Demo-iOS \
  clean test | xcpretty

PROJECT_PATH="derived_data/PocketSVG.xcodeproj"
MACOS_XCARCHIVE_PATH="derived_data/archives/PocketSVG-macOS.xcarchive"
IOS_SIMULATOR_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Simulator.xcarchive"
IOS_DEVICE_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Device.xcarchive"
XCFRAMEWORK_PATH="derived_data/xcframework/PocketSVG.xcframework"

echo "Build Swift Package"
swift build

echo "Build .xcframework"
swift package generate-xcodeproj --output $PROJECT_PATH

xcodebuild archive \
  -project $PROJECT_PATH \
  -scheme PocketSVG-Package \
  -destination 'platform=OS X,arch=x86_64' \
  -derivedDataPath derived_data \
  -archivePath $MACOS_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcpretty

xcodebuild archive \
  -project $PROJECT_PATH \
  -scheme PocketSVG-Package \
  -destination 'generic/platform=iOS' \
  -derivedDataPath derived_data \
  -archivePath $IOS_DEVICE_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcpretty

xcodebuild archive \
  -project $PROJECT_PATH \
  -scheme PocketSVG-Package \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath derived_data \
  -archivePath $IOS_SIMULATOR_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcpretty

IOS_SIMULATOR_FRAMEWORK_PATH=$(find $IOS_SIMULATOR_XCARCHIVE_PATH -name "*.framework")
IOS_DEVICE_FRAMEWORK_PATH=$(find $IOS_DEVICE_XCARCHIVE_PATH -name "*.framework")
MACOS_FRAMEWORK_PATH=$(find $MACOS_XCARCHIVE_PATH -name "*.framework")

xcodebuild -create-xcframework \
  -framework $IOS_SIMULATOR_FRAMEWORK_PATH \
  -framework $IOS_DEVICE_FRAMEWORK_PATH \
  -framework $MACOS_FRAMEWORK_PATH \
  -output $XCFRAMEWORK_PATH
