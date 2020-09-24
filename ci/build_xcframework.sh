#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xe

PROJECT_PATH="derived_data/PocketSVG.xcodeproj"
MACOS_XCARCHIVE_PATH="derived_data/archives/PocketSVG-macOS.xcarchive"
IOS_SIMULATOR_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Simulator.xcarchive"
IOS_DEVICE_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Device.xcarchive"
XCFRAMEWORK_PATH="derived_data/xcframework/PocketSVG.xcframework"

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
