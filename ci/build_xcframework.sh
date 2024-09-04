#
# This file is part of the PocketSVG package.
#
# Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
#!/usr/bin/env bash
set -xeo pipefail

IOS_SIMULATOR_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Simulator.xcarchive"
IOS_DEVICE_XCARCHIVE_PATH="derived_data/archives/PocketSVG-iOS-Device.xcarchive"
MACOS_XCARCHIVE_PATH="derived_data/archives/PocketSVG-macOS.xcarchive"
TVOS_XCARCHIVE_PATH="derived_data/archives/PocketSVG-tvOS.xcarchive"
CATALYST_XCARCHIVE_PATH="derived_data/archives/PocketSVG-Catalyst.xcarchive"
XCFRAMEWORK_PATH="derived_data/xcframework/PocketSVG.xcframework"

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=iOS' \
  -derivedDataPath derived_data \
  -archivePath $IOS_DEVICE_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath derived_data \
  -archivePath $IOS_SIMULATOR_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=macOS' \
  -derivedDataPath derived_data \
  -archivePath $MACOS_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=appletvos' \
  -derivedDataPath derived_data \
  -archivePath $TVOS_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath derived_data \
  -archivePath $CATALYST_XCARCHIVE_PATH \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

IOS_SIMULATOR_FRAMEWORK_PATH=$(find $IOS_SIMULATOR_XCARCHIVE_PATH -name "*.framework")
IOS_DEVICE_FRAMEWORK_PATH=$(find $IOS_DEVICE_XCARCHIVE_PATH -name "*.framework")
MACOS_FRAMEWORK_PATH=$(find $MACOS_XCARCHIVE_PATH -name "*.framework")
TVOS_FRAMEWORK_PATH=$(find $TVOS_XCARCHIVE_PATH -name "*.framework")
CATALYST_FRAMEWORK_PATH=$(find $CATALYST_XCARCHIVE_PATH -name "*.framework")

xcodebuild -create-xcframework \
  -framework $IOS_SIMULATOR_FRAMEWORK_PATH \
  -framework $IOS_DEVICE_FRAMEWORK_PATH \
  -framework $MACOS_FRAMEWORK_PATH \
  -framework $TVOS_FRAMEWORK_PATH \
  -framework $CATALYST_FRAMEWORK_PATH \
  -output $XCFRAMEWORK_PATH
