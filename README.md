# PocketSVG
A class that converts Scalable Vector Graphics (SVG) data into CGPaths, CAShapeLayers and UIBezierCurves. This makes it easy to create vector-based paths and shapes in your apps. 

This a fork of an [SVG to bezier path parser by Martin Haywood](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/), with fixes by [Pieter Omvlee](http://www.bohemiancoding.com/) and Dominic Mortlock.

Feedback, improvements, and pull requests are welcome. Please get in touch if you can help improve the code. 

## Usage
1. Make your drawing in a vector graphics editor such as Illustrator, Inkscape, [Sketch](http://www.bohemiancoding.com/sketch/), etc.
1. Save as an SVG.
1. Drag and drop it into your Xcode project.
1. Follow these easy steps:

```obj-c
    //1: Create a PocketSVG object from your SVG file:
    PocketSVG *myBezier = [[PocketSVG alloc] initFromSVGFileNamed:@"BezierCurve1-iPad"];
    
    //2: Its bezier property is the corresponding UIBezierPath:
    UIBezierPath *myPath = myBezier.bezier;
    
    //3: To display it on screen, create a CAShapeLayer and set 
    //the CGPath property of the above UIBezierPath as its path:
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myPath.CGPath;
    
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
* Fixed problem that causes SVGs to render with wrong frame dimensions.
* Fixed problem that causes some SVGs to render incorrectly.
* Fixed parse bug for SVGs with blank spaces in them (thanks to [mindbrix](https://github.com/mindbrix)).
* Simplified PocketSVG's init method (thanks to [johnnyknox](https://github.com/johnnyknox)).

## To Do
* Generate NSBezierPaths as well as UIBezierPaths
* Make it a category on CAShapeLayer?

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