/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


import XCTest
import PocketSVG

class PocketSVGTests: XCTestCase {
}

// we cannot include tests within the Swift Package because our tests rely on mock JSON files, and
// Swift Package Manager doesn't yet support resources. Till then, tests are in PocketSVGTests/
// and run via xcodebuild rather than swift test

// Also consider:
/*
 xcodebuild clean build-for-testing test \
 -scheme 'PocketSVG-Package' \
 -destination 'platform=iOS Simulator,name=iPhone 11,OS=13.4' \
 'OTHER_LDFLAGS=$(inherited) -Liphoneos -lxml2' \
 | xcpretty
 */
