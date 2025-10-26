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
VISIONOS_XCARCHIVE_PATH="derived_data/archives/PocketSVG-visionOS.xcarchive"
XCFRAMEWORK_PATH="derived_data/xcframework/PocketSVG.xcframework"

# 1. Build archives for each platform as static libs with module interfaces
xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=iOS' \
  -derivedDataPath derived_data \
  -archivePath "$IOS_DEVICE_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath derived_data \
  -archivePath "$IOS_SIMULATOR_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=macOS' \
  -derivedDataPath derived_data \
  -archivePath "$MACOS_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=appletvos' \
  -derivedDataPath derived_data \
  -archivePath "$TVOS_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath derived_data \
  -archivePath "$CATALYST_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

xcodebuild archive \
  -scheme PocketSVG \
  -destination 'generic/platform=visionOS' \
  -derivedDataPath derived_data \
  -archivePath "$VISIONOS_XCARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  | xcbeautify

# 2. Locate static libs + headers for each archive
IOS_DEVICE_LIB_PATH=$(find "$IOS_DEVICE_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
IOS_DEVICE_HEADERS_PATH=$(find "$IOS_DEVICE_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

IOS_SIM_LIB_PATH=$(find "$IOS_SIMULATOR_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
IOS_SIM_HEADERS_PATH=$(find "$IOS_SIMULATOR_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

MACOS_LIB_PATH=$(find "$MACOS_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
MACOS_HEADERS_PATH=$(find "$MACOS_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

TVOS_LIB_PATH=$(find "$TVOS_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
TVOS_HEADERS_PATH=$(find "$TVOS_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

CATALYST_LIB_PATH=$(find "$CATALYST_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
CATALYST_HEADERS_PATH=$(find "$CATALYST_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

VISIONOS_LIB_PATH=$(find "$VISIONOS_XCARCHIVE_PATH" -path "*/usr/local/lib/libPocketSVG.a")
VISIONOS_HEADERS_PATH=$(find "$VISIONOS_XCARCHIVE_PATH" -path "*/usr/local/include" -type d)

# Fallback headers dir for platforms that don't emit one (visionOS sometimes)
if [ -z "$VISIONOS_HEADERS_PATH" ]; then
  VISIONOS_HEADERS_PATH="derived_data/tmp_headers/visionos"
  mkdir -p "$VISIONOS_HEADERS_PATH"
fi

# Optional: debug output so you can see what got found
echo "IOS_DEVICE_LIB_PATH=$IOS_DEVICE_LIB_PATH"
echo "IOS_DEVICE_HEADERS_PATH=$IOS_DEVICE_HEADERS_PATH"
echo "IOS_SIM_LIB_PATH=$IOS_SIM_LIB_PATH"
echo "IOS_SIM_HEADERS_PATH=$IOS_SIM_HEADERS_PATH"
echo "MACOS_LIB_PATH=$MACOS_LIB_PATH"
echo "MACOS_HEADERS_PATH=$MACOS_HEADERS_PATH"
echo "TVOS_LIB_PATH=$TVOS_LIB_PATH"
echo "TVOS_HEADERS_PATH=$TVOS_HEADERS_PATH"
echo "CATALYST_LIB_PATH=$CATALYST_LIB_PATH"
echo "CATALYST_HEADERS_PATH=$CATALYST_HEADERS_PATH"
echo "VISIONOS_LIB_PATH=$VISIONOS_LIB_PATH"
echo "VISIONOS_HEADERS_PATH=$VISIONOS_HEADERS_PATH"

# 3. Build the static xcframework
xcodebuild -create-xcframework \
  -library "$IOS_DEVICE_LIB_PATH"    -headers "$IOS_DEVICE_HEADERS_PATH" \
  -library "$IOS_SIM_LIB_PATH"       -headers "$IOS_SIM_HEADERS_PATH" \
  -library "$MACOS_LIB_PATH"         -headers "$MACOS_HEADERS_PATH" \
  -library "$TVOS_LIB_PATH"          -headers "$TVOS_HEADERS_PATH" \
  -library "$CATALYST_LIB_PATH"      -headers "$CATALYST_HEADERS_PATH" \
  -library "$VISIONOS_LIB_PATH"      -headers "$VISIONOS_HEADERS_PATH" \
  -output "$XCFRAMEWORK_PATH"
