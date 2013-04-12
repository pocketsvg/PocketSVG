# PocketSVG
An Objective-C class that converts Scalable Vector Graphics (SVG) into:
* CGPaths
* CAShapeLayers
* UIBezierPaths
* NSBezierCurves. 

This makes it easy to create vector-based paths and shapes in your iOS or OS X apps. 

Feedback, improvements, and pull requests are welcome.

## Usage
1. Make your drawing in a vector graphics editor such as Illustrator, Inkscape, [Sketch](http://www.bohemiancoding.com/sketch/), etc.
1. Save as an SVG.
1. Drag and drop it into your Xcode project.
1. Follow these easy steps:

```obj-c
    //1: Create a PocketSVG object from your SVG file:
    PocketSVG *myVectorDrawing = [[PocketSVG alloc] initFromSVGFileNamed:@"BezierCurve3"];
    
    //2: Its bezier property is the corresponding UIBezierPath:
    UIBezierPath *myBezierPath = myVectorDrawing.bezier;
    
    //3: To display it on screen, create a CAShapeLayer and set 
    //the CGPath property of the above UIBezierPath as its 
    //path. 
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myBezierPath.CGPath;
    
    //4: Fiddle with it using CAShapeLayer's properties:
    myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
    myShapeLayer.lineWidth = 4;
    myShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    
    //5: Display it!
    [self.view.layer addSublayer:myShapeLayer];
```
Don't forget to add the __QuartzCore__ framework to your project ([here's how](http://stackoverflow.com/a/3377682/1072846)) and import it:
```obj-c
#import <QuartzCore/QuartzCore.h>
```

## Useful Documentation
* [An SVG's d attribute](http://www.w3.org/TR/SVG/paths.html#PathElement) – from the SVG specification 
* [UIBezierPaths](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIBezierPath_class/Reference/Reference.html) - Class Reference 
* [CAShapeLayers](https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAShapeLayer_class/Reference/Reference.html) - Class Reference. Tells you which properties of the shape/path can be manipulated. 
* [Drawing Shapes Using Bezier Paths](http://developer.apple.com/library/ios/#documentation/2ddrawing/conceptual/drawingprintingios/BezierPaths/BezierPaths.html) - From Apple's Drawing and Printing Guide for iOS

## Latest Fixes
* Added support for NSBezierPaths (thanks to [mcianni](https://github.com/mcianni)).
* Fixed problem that causes SVGs to render with wrong frame dimensions.
* Fixed problem that causes some SVGs to render incorrectly.
* Fixed parse bug for SVGs with blank spaces in them (thanks to [mindbrix](https://github.com/mindbrix)).
* Simplified PocketSVG's init method (thanks to [johnnyknox](https://github.com/johnnyknox)).

## To Do
* Support for SVG's [Basic Shapes](http://www.w3.org/TR/SVG/shapes.html).
* Support for SVGs with more than one path (currently PocketSVG renders the last path).
* Improve parser efficiency.
* Make it a category on CAShapeLayer?

## Support
Please ask questions and report bugs on [the project's Issues Page](https://github.com/arielelkin/PocketSVG/issues). 

## Contributors
* Martin Haywood (for the original [SVG to bezier path parser](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/) PocketSVG is based on).
* [Ariel Elkin](http://www.github.com/arielelkin)
* [Pieter Omvlee](http://www.bohemiancoding.com/)
* Dominic Mortlock
* [mcianni](https://github.com/mcianni)
* [mindbrix](https://github.com/mindbrix)
* [johnnyknox](https://github.com/johnnyknox)

## License

Copyright (c) 2013 Ponderwell, Ariel Elkin, and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

