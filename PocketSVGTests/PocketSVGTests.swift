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

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSVGAttributesFromRectangle() {
        let testBundle = Bundle(for: type(of: self))
        let svgURL = testBundle.url(forResource: "test_rectangle", withExtension: "svg")!

        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        //this is just a rectangle shape, so we should have just one path:
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

    func testPathsFromTiger() {
        let testBundle = Bundle(for: type(of: self))
        let svgURL = testBundle.url(forResource: "test_tiger", withExtension: "svg")!
        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        XCTAssert(paths.count == 240)

        let firstPath = UIBezierPath()
        firstPath.move(to: CGPoint(x: -122.30000305175781, y: 84.285003662109375))
        firstPath.addCurve(to: CGPoint(x: -123.0300030708313, y: 86.160003662109375), controlPoint1: CGPoint(x: -122.30000305175781, y: 84.285003662109375), controlPoint2: CGPoint(x: -122.2000030502677, y: 86.179003715515137))
        firstPath.addCurve(to: CGPoint(x: -160.83000230789185, y: 40.309001922607422), controlPoint1: CGPoint(x: -123.85000306367874, y: 86.141003662720323), controlPoint2: CGPoint(x: -140.30000352859497, y: 38.066001892089844))
        firstPath.addCurve(to: CGPoint(x: -122.30000352859497, y: 84.285003662109375), controlPoint1: CGPoint(x: -160.83000230789185, y: 40.309001922607422), controlPoint2: CGPoint(x: -143.05000162124634, y: 32.956001758575439))
        firstPath.close()
        XCTAssert(firstPath.cgPath == paths[0].cgPath)


        let hundredthPath = UIBezierPath()
        hundredthPath.move(to: CGPoint(x: 294.5, y: 153))
        hundredthPath.addCurve(to: CGPoint(x: 242, y: 123), controlPoint1: CGPoint(x: 294.5, y: 153), controlPoint2: CGPoint(x: 249.5, y: 124.5))
        hundredthPath.addCurve(to: CGPoint(x: 296.5, y: 162.5), controlPoint1: CGPoint(x: 230.1899995803833, y: 120.64000010490417), controlPoint2: CGPoint(x: 291.5, y: 152))
        hundredthPath.addCurve(to: CGPoint(x: 294.5, y: 153), controlPoint1: CGPoint(x: 296.5, y: 162.5), controlPoint2: CGPoint(x: 298.5, y: 160))
        hundredthPath.close()
        XCTAssert(hundredthPath.cgPath == paths[100].cgPath)
    }

    func testSVGRepresentationWhenUsingSettingSVGAttributes() {
        let attributes: [String: Any] = [
            "stroke": "black",
            "stroke-width": "2",
            "fill": "transparent"
        ]
        let bezierPath = SVGBezierPath().settingSVGAttributes(attributes)

        let representation = "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"0\" height=\"0\">\n  <path stroke=\"black\" fill=\"transparent\" stroke-width=\"2\" d=\"\"/>\n\n</svg>\n"

        XCTAssertEqual(bezierPath.svgRepresentation, representation)
    }

    func testSVGAttributesAreCorrectlySetWhenInitingWithAttributes() {
        let attributes: [String: Any] = [
            "stroke": "black",
            "stroke-width": "2",
            "fill": "transparent"
        ]

        let bezierPath = SVGBezierPath().settingSVGAttributes(attributes)

        XCTAssert(bezierPath.svgAttributes["stroke"] as! String == "black")
        XCTAssert(bezierPath.svgAttributes["stroke-width"] as! String == "2")
        XCTAssert(bezierPath.svgAttributes["fill"] as! String == "transparent")
    }

    func testSVGRepresentationWithRectangle() {
        let testBundle = Bundle(for: type(of: self))
        let svgURL = testBundle.url(forResource: "test_rectangle", withExtension: "svg")!

        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)
        XCTAssert(paths.count == 1)
        let rectanglePath = paths[0]

        let representation = "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"100\" height=\"100\">\n  <path stroke=\"#fff000\" id=\"Page-1\" stroke-width=\"2px\" x=\"0\" sketch:type=\"MSPage\" rx=\"10px\" y=\"0\" fill-rule=\"evenodd\" width=\"100px\" fill=\"#ffffff\" fill-opacity=\"0\" ry=\"10px\" height=\"100px\" d=\"M100,50L100,90C100,95.523,95.523,100,90,100L10,100C4.477,100,0,95.523,0,90L0,10C0,4.477,4.477,-0,10,0L90,0C95.523,0,100,4.477,100,10Z\"/>\n\n</svg>\n"

        XCTAssertEqual(rectanglePath.svgRepresentation, representation)
    }

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

        guard let path = paths.first else {
            return
        }

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform();
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

        guard let path = paths.first else {
            return
        }

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform();
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

        guard let path = paths.first else {
            return
        }

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform();
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

        guard let path = paths.first else {
            return
        }

        let pathTransform = (path.svgAttributes["transform"]! as! NSValue).svg_CGAffineTransform();
        XCTAssertEqual(pathTransform, CGAffineTransform(scaleX: 2, y: 2))
    }

}
