/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import Foundation
#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle {
        Bundle(for: PocketSVGTests.self)
    }
}
#endif

import PocketSVG
import QuartzCore
import XCTest

class PocketSVGTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testFillRuleControlsBezierPathHoles() throws {
        let shape = "M0 0H20V20H0Z M5 5H15V15H5Z"
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <g fill-rule="evenodd">
                <path d="\(shape)"/>
                <path d="\(shape)" fill-rule="nonzero"/>
                <path d="\(shape)" style="fill-rule: nonzero;"/>
            </g>
            <path d="\(shape)"/>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svg)
        XCTAssertEqual(paths.count, 4)
        guard paths.count == 4 else { return }
        for (index, path) in paths.enumerated() {
            // Both subpaths have the same direction. Only evenodd leaves a hole.
            XCTAssertEqual(path.contains(CGPoint(x: 10, y: 10)), index != 0)
            XCTAssertTrue(path.contains(CGPoint(x: 2, y: 2)))
        }

        let layer = SVGLayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        layer.paths = paths
        layer.layoutSublayers()
        let shapeLayers = try XCTUnwrap(layer.sublayers as? [CAShapeLayer])
        XCTAssertEqual(shapeLayers.map(\.fillRule), [.evenOdd, .nonZero, .nonZero, .nonZero])
    }

    func testSettingFillRuleUpdatesCopiedPathWithoutChangingOriginal() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0H20V20H0Z M5 5H15V15H5Z" fill-rule="evenodd"/>
        </svg>
        """
        let original = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: svg).first)
        let copied = try XCTUnwrap(original.copy() as? SVGBezierPath)
        let nonZero = try XCTUnwrap(original.settingSVGAttributes(["fill-rule": "nonzero"]))
        let evenOdd = try XCTUnwrap(nonZero.settingSVGAttributes(["fill-rule": "evenodd"]))
        let center = CGPoint(x: 10, y: 10)
        XCTAssertFalse(original.contains(center))
        XCTAssertFalse(copied.contains(center))
        XCTAssertTrue(nonZero.contains(center))
        XCTAssertFalse(evenOdd.contains(center))
        XCTAssertEqual(original.svgAttributes["fill-rule"] as? String, "evenodd")
    }

    func testFillRuleIsPreservedAcrossCachedLoads() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".svg")
        defer {
            try? FileManager.default.removeItem(at: url)
            SVGBezierPath.resetCache()
        }
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd">
            <path d="M0 0H20V20H0Z M5 5H15V15H5Z"/>
        </svg>
        """
        try svg.write(to: url, atomically: true, encoding: .utf8)
        let first = try XCTUnwrap(SVGBezierPath.pathsFromSVG(at: url).first)
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            first.usesEvenOddFillRule = false
        #else
            first.windingRule = .nonZero
        #endif
        let cached = try XCTUnwrap(SVGBezierPath.pathsFromSVG(at: url).first)
        XCTAssertFalse(cached.contains(CGPoint(x: 10, y: 10)))
        XCTAssertFalse(first === cached)
    }

    // Original source from #217's issue body:
    // https://github.com/pocketsvg/PocketSVG/assets/18410283/7dc923a1-f19c-4f54-9870-05174734030d
    // The butterfly in the later comment was never uploaded. This fixture uses
    // unsupported stylesheet classes, so this checks geometry, not visual parity.
    func testIssue217ExportRetainsGeometryAfterDefinitions() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "test_issue217_export", withExtension: "svg"))
        let paths = SVGBezierPath.pathsFromSVG(at: url)
        XCTAssertEqual(paths.count, 10)
        guard paths.count == 10 else { return }
        let outline = paths[3].cgPath.boundingBoxOfPath
        XCTAssertEqual(outline.minX, 0.85, accuracy: 1e-3)
        XCTAssertEqual(outline.minY, 0.85, accuracy: 1e-3)
        XCTAssertEqual(outline.maxX, 173.59, accuracy: 1e-3)
        XCTAssertEqual(outline.maxY, 236.12, accuracy: 1e-3)
    }

    // A retained Core Foundation return imports directly as a managed CGPath.
    // Removing CF_RETURNS_RETAINED changes this to Unmanaged<CGPath> and fails
    // compilation, guarding the ownership contract fixed for #231 in 3.1.0.
    func testIsolatedPathHasManagedSwiftOwnership() throws {
        let path: CGPath = try XCTUnwrap(CGPathFromSVGPathString("M0 0L10 20"))
        XCTAssertEqual(path.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 20))
    }

    // Regression for #161: the supplied SVG contains two gradient references.
    func testUnsupportedGradientsAreTransparent() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "test_unsupported_gradients", withExtension: "svg"))
        let paths = SVGBezierPath.pathsFromSVG(at: url)
        XCTAssertEqual(paths.count, 3)
        guard paths.count == 3 else { return }

        for path in paths.prefix(2) {
            let fill = path.svgAttributes["fill"] as! CGColor
            XCTAssertEqual(fill.alpha, 0)
        }
        let whiteFill = paths[2].svgAttributes["fill"] as! CGColor
        XCTAssertEqual(whiteFill.components!, [1, 1, 1, 1])
    }

    func testInvalidPaintsAreTransparent() throws {
        let paints = [
            "url(#missing)", "currentColor", "unknown", "", "#", "#12", "#12345", "#gggggg",
            "rgb(", "rgb()", "rgb(1,2)", "rgb(1,2,3,4)", "rgb(1,no,3)", "rgb(1,2,3)junk", "rgb(1,2,3x)", "#１２３",
            "rgb(100%, 50, 0%)", "rgb(100%, 50%, 0%junk)", "rgb(nan,0,0)", "rgb(inf,0,0)",
        ]
        for paint in paints {
            let svg = """
            <svg xmlns="http://www.w3.org/2000/svg">
                <rect width="10" height="10" fill="\(paint)" stroke="\(paint)" fill-opacity="0.5" stroke-opacity="0.5"/>
            </svg>
            """
            let paths = SVGBezierPath.paths(fromSVGString: svg)
            XCTAssertEqual(paths.count, 1, paint)
            let path = try XCTUnwrap(paths.first)
            for attribute in ["fill", "stroke"] {
                let color = path.svgAttributes[attribute] as! CGColor
                XCTAssertEqual(color.alpha, 0, "\(attribute)=\(paint)")
            }
        }
    }

    func testUnsupportedPaintOverridesInheritedPaintAndPreservesValidStroke() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" fill="red">
            <g style="fill: url(#gradient); fill-opacity: 0.5;">
                <rect width="10" height="10" stroke="#00ff00" stroke-opacity="0.5"/>
            </g>
            <rect x="20" width="10" height="10"/>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svg)
        XCTAssertEqual(paths.count, 2)
        guard paths.count == 2 else { return }
        let fill = paths[0].svgAttributes["fill"] as! CGColor
        let stroke = paths[0].svgAttributes["stroke"] as! CGColor
        let siblingFill = paths[1].svgAttributes["fill"] as! CGColor
        XCTAssertEqual(fill.alpha, 0)
        XCTAssertEqual(stroke.components!, [0, 1, 0, 0.5])
        XCTAssertEqual(siblingFill.components!, [1, 0, 0, 1])
    }

    func testSupportedColorFormats() throws {
        let paints = ["#f80", "#FF8800", "rgb(255, 136, 0)", " RGB(255, 136, 0) ", "rgb(300, 136, -1)",
                      "rgb(255.0, 136.0, 0.0)", "rgb(100%, 53.3%, 0%)", "rgb(120%, 53.3%, -10%)"]
        for paint in paints {
            let svg = """
            <svg xmlns="http://www.w3.org/2000/svg">
                <rect width="10" height="10" fill="\(paint)"/>
            </svg>
            """
            let path = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: svg).first)
            let fill = path.svgAttributes["fill"] as! CGColor
            XCTAssertEqual(fill.components!, [1, CGFloat(136) / 255, 0, 1], paint)
        }
    }

    func testChildOpacityOverridesInheritedOpacity() throws {
        for opacity in ["0", "0.5", "1"] {
            let svg = """
            <svg xmlns="http://www.w3.org/2000/svg" fill="red" stroke="blue" fill-opacity="0.5" stroke-opacity="0.5">
                <g fill-opacity="0.8" stroke-opacity="0.8">
                    <rect width="10" height="10" fill-opacity="\(opacity)" stroke-opacity="\(opacity)"/>
                    <rect x="20" width="10" height="10"/>
                    <rect x="40" width="10" height="10" fill="green" stroke="red"/>
                </g>
            </svg>
            """
            let paths = SVGBezierPath.paths(fromSVGString: svg)
            XCTAssertEqual(paths.count, 3)
            guard paths.count == 3 else { return }
            for attribute in ["fill", "stroke"] {
                let child = paths[0].svgAttributes[attribute] as! CGColor
                let inherited = paths[1].svgAttributes[attribute] as! CGColor
                let overriddenPaint = paths[2].svgAttributes[attribute] as! CGColor
                XCTAssertEqual(child.alpha, CGFloat(Double(opacity)!), accuracy: 1e-6)
                XCTAssertEqual(inherited.alpha, 0.8, accuracy: 1e-6)
                XCTAssertEqual(overriddenPaint.alpha, 0.8, accuracy: 1e-6)
            }
        }
    }

    func testInheritedTransparentPaintRemainsTransparentWhenOpacityIsOverridden() throws {
        for paint in ["none", "url(#gradient)"] {
            let svg = """
            <svg xmlns="http://www.w3.org/2000/svg" fill="\(paint)" stroke="\(paint)" fill-opacity="0.5" stroke-opacity="0.5">
                <rect width="10" height="10" fill-opacity="0.8" stroke-opacity="0.8"/>
                <rect x="20" width="10" height="10" fill="red" stroke="blue"/>
            </svg>
            """
            let paths = SVGBezierPath.paths(fromSVGString: svg)
            XCTAssertEqual(paths.count, 2)
            guard paths.count == 2 else { return }
            for attribute in ["fill", "stroke"] {
                let transparent = paths[0].svgAttributes[attribute] as! CGColor
                let overridden = paths[1].svgAttributes[attribute] as! CGColor
                XCTAssertEqual(transparent.alpha, 0)
                XCTAssertEqual(overridden.alpha, 0.5)
            }
        }
    }

    func testNoneRemainsTransparentWithOpacity() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <rect width="10" height="10" fill="none" stroke="none" fill-opacity="0.5" stroke-opacity="0.5"/>
        </svg>
        """
        let path = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: svg).first)
        for attribute in ["fill", "stroke"] {
            let color = path.svgAttributes[attribute] as! CGColor
            XCTAssertEqual(color.alpha, 0)
        }
    }

    func testSVGAttributesFromRectangle() {
        let svgURL = Bundle.module.url(forResource: "test_rectangle", withExtension: "svg")!

        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        // this is just a rectangle shape, so we should have just one path:
        XCTAssert(paths.count == 1)

        let rectanglePath = paths[0]

        XCTAssert(rectanglePath.svgAttributes["x"] as! String == "0")
        XCTAssert(rectanglePath.svgAttributes["y"] as! String == "0")
        XCTAssert(rectanglePath.svgAttributes["rx"] as! String == "10px")
        XCTAssert(rectanglePath.svgAttributes["ry"] as! String == "10px")
        XCTAssert(rectanglePath.svgAttributes["fill-rule"] as! String == "evenodd")
        XCTAssert(rectanglePath.svgAttributes["stroke-width"] as! String == "2px")
        XCTAssert(rectanglePath.svgAttributes["width"] as! String == "100px")
        XCTAssert(rectanglePath.svgAttributes["height"] as! String == "100px")
    }

    #if os(iOS)
        func testPathsFromTiger() {
            let svgURL = Bundle.module.url(forResource: "test_tiger", withExtension: "svg")!
            let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

            XCTAssert(paths.count == 240)

            let firstPath = UIBezierPath()
            firstPath.move(to: CGPoint(x: -122.30000305175781, y: 84.285003662109375))
            firstPath.addCurve(to: CGPoint(x: -123.0300030708313, y: 86.160003662109375), controlPoint1: CGPoint(x: -122.30000305175781, y: 84.285003662109375), controlPoint2: CGPoint(x: -122.2000030502677, y: 86.179003715515137))
            firstPath.addCurve(to: CGPoint(x: -160.83000230789185, y: 40.309001922607422), controlPoint1: CGPoint(x: -123.85000306367874, y: 86.141003662720323), controlPoint2: CGPoint(x: -140.30000352859497, y: 38.066001892089844))
            firstPath.addCurve(to: CGPoint(x: -122.30000352859497, y: 84.285003662109375), controlPoint1: CGPoint(x: -160.83000230789185, y: 40.309001922607422), controlPoint2: CGPoint(x: -143.05000162124634, y: 32.956001758575439))
            firstPath.close()
            XCTAssertEqual(firstPath.cgPath, paths[0].cgPath)

            let hundredthPath = UIBezierPath()
            hundredthPath.move(to: CGPoint(x: 294.5, y: 153))
            hundredthPath.addCurve(to: CGPoint(x: 242, y: 123), controlPoint1: CGPoint(x: 294.5, y: 153), controlPoint2: CGPoint(x: 249.5, y: 124.5))
            hundredthPath.addCurve(to: CGPoint(x: 296.5, y: 162.5), controlPoint1: CGPoint(x: 230.1899995803833, y: 120.64000010490417), controlPoint2: CGPoint(x: 291.5, y: 152))
            hundredthPath.addCurve(to: CGPoint(x: 294.5, y: 153), controlPoint1: CGPoint(x: 296.5, y: 162.5), controlPoint2: CGPoint(x: 298.5, y: 160))
            hundredthPath.close()
            XCTAssertEqual(hundredthPath.cgPath, paths[100].cgPath)
        }
    #endif

    func testSVGRepresentationWhenUsingSettingSVGAttributes() {
        let attributes: [String: Any] = [
            "stroke": "black",
            "stroke-width": "2",
            "fill": "transparent",
        ]
        let bezierPath = SVGBezierPath().settingSVGAttributes(attributes)

        XCTAssert(bezierPath!.svgRepresentation.contains("stroke-width=\"2\""))
        XCTAssert(bezierPath!.svgRepresentation.contains("stroke=\"black\""))
        XCTAssert(bezierPath!.svgRepresentation.contains("fill=\"transparent\""))
        XCTAssert(bezierPath!.svgRepresentation.contains("d=\"\"/>\n\n"))
    }

    func testSVGAttributesAreCorrectlySetWhenInitingWithAttributes() {
        let attributes: [String: Any] = [
            "stroke": "black",
            "stroke-width": "2",
            "fill": "transparent",
        ]

        let bezierPath = SVGBezierPath().settingSVGAttributes(attributes)

        XCTAssert(bezierPath!.svgAttributes["stroke"] as! String == "black")
        XCTAssert(bezierPath!.svgAttributes["stroke-width"] as! String == "2")
        XCTAssert(bezierPath!.svgAttributes["fill"] as! String == "transparent")
    }

    func testSVGRepresentationWithRectangle() {
        let svgURL = Bundle.module.url(forResource: "test_rectangle", withExtension: "svg")!

        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)
        XCTAssert(paths.count == 1)
        let rectanglePath = paths[0]

        let representation = "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"100\" height=\"100\">\n  <path stroke=\"#fff000\" id=\"Page-1\" stroke-width=\"2px\" version=\"1.1\" sketch:type=\"MSPage\" x=\"0\" width=\"100px\" fill=\"#ffffff\" fill-opacity=\"0\" fill-rule=\"evenodd\" y=\"0\" rx=\"10px\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:sketch=\"http://www.bohemiancoding.com/sketch/ns\" ry=\"10px\" height=\"100px\" viewBox=\"0 0 300 300\" xmlns=\"http://www.w3.org/2000/svg\" d=\"M100,50L100,90C100,95.523,95.523,100,90,100L10,100C4.477,100,0,95.523,0,90L0,10C0,4.477,4.477,-0,10,0L90,0C95.523,0,100,4.477,100,10Z\"/>\n\n</svg>\n"

        XCTAssertEqual(rectanglePath.svgRepresentation, representation)
    }

    func testZeroFollowedByWhitespaceAndFractionIsKept() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0 L0 0 0 .25"/>
        </svg>
        """

        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)

        let boundingBox = paths[0].cgPath.boundingBoxOfPath
        XCTAssertEqual(boundingBox.width, 0, accuracy: 1e-6)
        XCTAssertEqual(boundingBox.height, 0.25, accuracy: 1e-6)
    }

    func testExponentNotationStartingWithZeroIsParsed() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0 L0e-5 1"/>
        </svg>
        """

        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)

        let boundingBox = paths[0].cgPath.boundingBoxOfPath
        XCTAssertEqual(boundingBox.height, 1, accuracy: 1e-6)
    }

    func testIgnoresMaskElement() {
        let svgString = """
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px">
            <g>
                <mask>
                    <g>
                        <rect width="100" height="100" style="fill: #FFFFFF" />
                    </g>
                </mask>
                <rect x="20" y="20" width="60" height="60" style="fill: #FF0000"/>
            </g>
        </svg>
        """

        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first

        XCTAssertEqual(path!.bounds, CGRect(x: 20, y: 20, width: 60, height: 60))
    }

    #if os(iOS)
        func testRespectsAttributesOnAElement() {
            let svgString = """
            <svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px">
                <a transform="translate(5 10)">
                    <rect x="15" y="10" width="60" height="60"/>
                </a>
            </svg>
            """

            let paths = SVGBezierPath.paths(fromSVGString: svgString)
            XCTAssertEqual(paths.count, 1)
            let path = paths.first!

            let pathTransform = (path.svgAttributes["transform"]! as! NSValue).cgAffineTransformValue
            let pathBounds = path.bounds
            let translatedPathBounds = pathBounds.applying(pathTransform)

            XCTAssertEqual(pathTransform, CGAffineTransform(translationX: 5, y: 10))
            XCTAssertEqual(pathBounds, CGRect(x: 15, y: 10, width: 60, height: 60))
            XCTAssertEqual(translatedPathBounds, CGRect(x: 20, y: 20, width: 60, height: 60))
        }
    #endif

    func testTransformTranslate() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10 5)">
                <rect x="20" y="20" width="60" height="60"/>
            </g>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first!

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform()
        XCTAssertEqual(pathTransform, CGAffineTransform(translationX: 10, y: 5))
    }

    func testTransformTranslateOptionalParameters() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10)">
                <rect x="20" y="20" width="60" height="60"/>
            </g>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first!

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform()
        XCTAssertEqual(pathTransform, CGAffineTransform(translationX: 10, y: 0))
    }

    func testTransformScale() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <g transform="scale(2 2)">
                <rect x="20" y="20" width="30" height="30"/>
            </g>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first!

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform()
        XCTAssertEqual(pathTransform, CGAffineTransform(scaleX: 2, y: 2))
    }

    func testTransformScaleOptionalParameters() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <g transform="scale(2)">
                <rect x="20" y="20" width="60" height="60"/>
            </g>
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first!

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform()
        XCTAssertEqual(pathTransform, CGAffineTransform(scaleX: 2, y: 2))
    }

    /**
     * Test that path bounding boxes are correct to prevent issues like
     * https://github.com/pocketsvg/PocketSVG/issues/128
     */
    func testBoundingBox() {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M21 256 l0 -235 235 0 235 0 0 235 0 235 -235 0 -235 0 0 -235z" />
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        XCTAssertEqual(paths.count, 1)
        let path = paths.first!
        XCTAssertEqual(path.cgPath.boundingBox, CGRect(x: 21, y: 21, width: 470, height: 470))
    }

    // Exact arc fragments from the Illustrator SVG attached to #227. In #205,
    // scanning the dot skipped the preceding comma and discarded an arc flag.
    func testIllustratorArcsKeepZeroFlagsBeforeSeparatedFractions() throws {
        let cases = [
            ("A8.77322,8.77322,0,0,0,.5801,145.57636",
             "A 8.77322 8.77322 0 0 0 0.5801 145.57636", CGPoint(x: 0.5801, y: 145.57636)),
            ("a88.66989,88.66989,0,0,0,.069-20.11339",
             "a 88.66989 88.66989 0 0 0 0.069 -20.11339", CGPoint(x: 0.069, y: -20.11339)),
        ]
        for (compact, separated, endpoint) in cases {
            let compactSVG = "<svg><path d=\"M0 0 \(compact)\"/></svg>"
            let separatedSVG = "<svg><path d=\"M0 0 \(separated)\"/></svg>"
            let compactPath = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: compactSVG).first?.cgPath)
            let separatedPath = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: separatedSVG).first?.cgPath)
            XCTAssertEqual(compactPath, separatedPath, compact)
            XCTAssertEqual(compactPath.currentPoint.x, endpoint.x, accuracy: 1e-5)
            XCTAssertEqual(compactPath.currentPoint.y, endpoint.y, accuracy: 1e-5)
        }
    }

    func testIllustratorSignedFractionalCurveCoordinates() throws {
        let compact = "<svg><path d=\"M0 0 c-2.82635-.641-6.70644.67519-11.55837,3.909\"/></svg>"
        let separated = "<svg><path d=\"M0 0 c -2.82635 -0.641 -6.70644 0.67519 -11.55837 3.909\"/></svg>"
        let compactPath = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: compact).first?.cgPath)
        let separatedPath = try XCTUnwrap(SVGBezierPath.paths(fromSVGString: separated).first?.cgPath)
        XCTAssertEqual(compactPath, separatedPath)
        XCTAssertEqual(compactPath.currentPoint.x, -11.55837, accuracy: 1e-5)
        XCTAssertEqual(compactPath.currentPoint.y, 3.909, accuracy: 1e-5)
    }

    // Original attachment: https://github.com/pocketsvg/PocketSVG/issues/227
    func testIllustratorCactiMatchesExplicitFractionalCoordinates() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "test_illustrator_cacti", withExtension: "svg"))
        let svg = try String(contentsOf: url, encoding: .utf8)
        // A fraction starting after a separator or sign can spell out its leading
        // zero without changing its value. Leave existing decimal points alone.
        let explicitFractions = svg.replacingOccurrences(
            of: #"(?<![0-9])\.(?=[0-9])"#, with: "0.", options: .regularExpression
        )
        let compactPaths = SVGBezierPath.paths(fromSVGString: svg)
        let explicitPaths = SVGBezierPath.paths(fromSVGString: explicitFractions)
        // The attachment contains 242 paths and two polygons.
        XCTAssertEqual(compactPaths.count, 244)
        XCTAssertEqual(explicitPaths.count, compactPaths.count)
        for (compact, explicit) in zip(compactPaths, explicitPaths) {
            XCTAssertEqual(compact.cgPath, explicit.cgPath)
        }
    }

    /**
     * Test that leading zeros shortcuts are not ignored and properly parsed
     * https://github.com/pocketsvg/PocketSVG/issues/204
     */
    func testPathValuesWithLeadingZeros() throws {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M 0 0.01 a 2 1 0 0 0 6 0 a 0.24 0.52 0 0 0 0 1001" />
        </svg>
        """
        let shortcutSvgString = """
        <svg xmlns="http://www.w3.org/2000/svg">
            <path d="M 00.01 a 2 1 0 006 0 a 0.24.52 000 01001" />
        </svg>
        """
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        let cgPath = try XCTUnwrap(paths.first?.cgPath)
        let shortcutPaths = SVGBezierPath.paths(fromSVGString: shortcutSvgString)
        let shortcutCgPath = try XCTUnwrap(shortcutPaths.first?.cgPath)
        XCTAssertEqual(cgPath, shortcutCgPath, "Reference and shortcut paths should be equal")
    }
}
