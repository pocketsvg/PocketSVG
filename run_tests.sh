## this script builds the iOS and macOS frameworks and demos, and
## runs the tests on iOS. It is called from Travis CI (via .travis.yml)
## and placed in a separate file for better readability.

IPHONE6SIM="platform=iOS Simulator,name=iPhone 6,OS=11.2"

## build iOS framework:
set -o pipefail && \
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme "PocketSVG (iOS)" \
  -destination "$IPHONE6SIM" \
  clean build | xcpretty

## build macOS framework:
set -o pipefail && \
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme "PocketSVG (Mac)" \
  -destination "arch=x86_64" \
  clean build | xcpretty

## build iOS demo:
set -o pipefail && \
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "$IPHONE6SIM" \
  -scheme Demo-iOS \
  clean build | xcpretty

## build macOS demo:
set -o pipefail && \
xcodebuild \
  -workspace Demos/Demos.xcworkspace \
  -destination "arch=x86_64" \
  -scheme Demo-macOS \
  clean build | xcpretty

## run tests:
set -o pipefail && \
xcodebuild \
  -project PocketSVG.xcodeproj \
  -scheme PocketSVGTests \
  -destination "$IPHONE6SIM" \
  test | xcpretty
