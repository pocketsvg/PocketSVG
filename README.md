# PocketSVG
An Objective-C class that converts Scalable Vector Graphics (SVG) into:
* CGPaths
* CAShapeLayers
* UIBezierPaths
* NSBezierCurves 

This makes it easy to create vector-based paths and shapes in your iOS or OS X apps. 

Feedback, improvements, and pull requests are welcome.

[![Build Status](https://travis-ci.org/arielelkin/PocketSVG.svg?branch=master)](https://travis-ci.org/arielelkin/PocketSVG)

## Usage
Drag and drop the SVG files into your Xcode project. 

###Swift
1. Xcode will ask "**Would you like to configure an Objective-C bridging header?**", Click **Yes**.
1. Add this line to the bridging header file:
`#import "PocketSVG.h"`
1. Follow these simple steps:

```swift
//1: Turn your SVG into a CGPath:
let myPath = PocketSVG.pathFromSVGFileNamed("BezierCurve1").takeUnretainedValue()

//2: To display it on screen, you can create a CAShapeLayer
//and set myPath as its path property:
let myShapeLayer = CAShapeLayer()
myShapeLayer.path = myPath

//3: Fiddle with it using CAShapeLayer's properties:
myShapeLayer.strokeColor = UIColor.redColor().CGColor
myShapeLayer.lineWidth = 3
myShapeLayer.fillColor = UIColor.clearColor().CGColor

//4: Display it!
self.view.layer.addSublayer(myShapeLayer)
```

###Objective-C

```obj-c
//1: Turn your SVG into a CGPath:
CGPathRef myPath = [PocketSVG pathFromSVGFileNamed:@"BezierCurve1"];

//2: To display it on screen, you can create a CAShapeLayer
//and set myPath as its path property:
CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
myShapeLayer.path = myPath;

//3: Fiddle with it using CAShapeLayer's properties:
myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
myShapeLayer.lineWidth = 4;
myShapeLayer.fillColor = [[UIColor clearColor] CGColor];

//4: Display it!
[self.view.layer addSublayer:myShapeLayer];
```

## Useful Documentation
* [The 'path' element of an SVG](http://www.w3.org/TR/SVG/paths.html#PathElement) – from the SVG specification. PocketSVG uses the data in the SVG's **d=** attribute, which defines the outlines of shapes. 
* [Core Graphics Paths](https://developer.apple.com/library/mac/documentation/graphicsimaging/Conceptual/drawingwithquartz2d/dq_paths/dq_paths.html#//apple_ref/doc/uid/TP30001066-CH211-TPXREF101) – from Apple's Quartz 2D Programming Guide.
* [CGPath](https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CGPath/Reference/reference.html) - Class Reference.
* [CAShapeLayers](https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAShapeLayer_class/Reference/Reference.html) – Class Reference. Tells you which properties of the shape/path can be manipulated. 
* [Drawing Shapes Using Bezier Paths](http://developer.apple.com/library/ios/#documentation/2ddrawing/conceptual/drawingprintingios/BezierPaths/BezierPaths.html) – From Apple's Drawing and Printing Guide for iOS.

## To Do
* Support for SVG's [Basic Shapes](http://www.w3.org/TR/SVG/shapes.html).
* Support for SVGs with more than one path (currently PocketSVG renders the last path).
* Improve parser efficiency.

## Support
Please ask questions and report bugs on [the project's Issues Page](https://github.com/arielelkin/PocketSVG/issues). 

## Contributors
* Martin Haywood (for the original [SVG to bezier path parser](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/) PocketSVG is based on).
* [Ariel Elkin](http://www.github.com/arielelkin)
* [Pieter Omvlee](http://www.bohemiancoding.com/)
* Dominic Mortlock
* [And more](https://github.com/arielelkin/PocketSVG/graphs/contributors).

## License

Copyright (c) 2013 Ponderwell, Ariel Elkin, and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
