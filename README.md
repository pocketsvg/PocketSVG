# PocketSVG
A library that converts Scalable Vector Graphics (SVG) data into CAShapeLayers and UIBezierCurves. This makes it easy to create vector-based paths and shapes in your apps. 

This a fork of an [SVG to bezier path parser by Martin Haywood](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/), with fixes by [Pieter Omvlee](http://www.bohemiancoding.com/) and Dominic Mortlock.

Feedback, improvements, and pull requests are welcome. Please get in touch if you can help improve the code. 

## Usage
1. Draw your bezier path in a vector graphics editor such as Illustrator, Inkscape, [Sketch](http://www.bohemiancoding.com/sketch/), etc.
1. Save as an SVG
1. Drag and drop it into your Xcode project 
1. Create an SvgToBezier object:

```obj-c
    //Set the frame in which to draw the SVG:
    CGRect frameRect = CGRectMake(0, 0, 1024, 768);

    //Create an SvgToBezier object:
    SvgToBezier *myBezier = [[SvgToBezier alloc] initFromSVGFileNamed:@"BezierCurve1-iPad" rect:frameRect];
```
To then render it as an `UIBezierPath`:

```obj-c
    UIBezierPath *myPath = myBezier.bezier;
```
To render it as a `CAShapeLayer`:
```obj-c
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myPath.CGPath;
    
    myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
    myShapeLayer.lineWidth = 4;
    
    myShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    
    [self.view.layer addSublayer:myShapeLayer];
```

## Useful Documentation
* [An SVG's d attribute](http://www.w3.org/TR/SVG/paths.html#PathElement) – from the SVG specification 
* [UIBezierPaths](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIBezierPath_class/Reference/Reference.html) - Class Reference 
* [CAShapeLayers](https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAShapeLayer_class/Reference/Reference.html) - Class Reference 
* [Drawing Shapes Using Bezier Paths](http://developer.apple.com/library/ios/#documentation/2ddrawing/conceptual/drawingprintingios/BezierPaths/BezierPaths.html) - From Apple's Drawing and Printing Guide for iOS

## Latest Fixes
* Fixed problem that causes SVGs to render with wrong frame dimensions.
* Fixed problem that causes some SVGs to render incorrectly.

## To Do
* Generate NSBezierPaths as well as UIBezierPaths

## Support 
Please ask questions and report bugs on [the project's Issues Page](https://github.com/arielelkin/PocketSVG/issues). 

## License
[Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license] (http://creativecommons.org/licenses/by-sa/3.0)

You are free:

* to __Share__ — to copy, distribute and transmit the work
* to __Remix__ — to adapt the work
* to make commercial use of the work

Under the following conditions:
* __Attribution__ — You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).
* __Share Alike__ — If you alter, transform, or build upon this work, you may distribute the resulting work only under the same or similar license to this one.