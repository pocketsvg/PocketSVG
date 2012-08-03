# PocketSVG
A library that converts Scalable Vector Graphics (SVG) data into CAShapeLayers and UIBezierCurves. This makes it easy to create vector-based paths and shapes in your apps. 

This a fork of an [SVG to bezier path parser by Martin Haywood](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/), with fixes by [Pieter Omvlee](http://www.bohemiancoding.com/).

Want to add a new feature and improve PocketSVG? Pull requests and collaborators are welcome. 

## Instructions
1. Draw your bezier path in your favourite vector graphics app
1. Save as an SVG
1. Open the SVG file in your text editor, and copy the contents of its `d` attribute.
1. Use this to initialize a new `SvgToBezier` object: 

```obj-c
    //Create an SvgTobezier with the content of our SVG's d attribute:
    SvgToBezier *myBezier = [[SvgToBezier alloc] initFromSVGPathNodeDAttr:@"M176.17,369.617c0,0,335.106-189.361,214.894,38.298s129.787,282.978,178.723,42.553C618.724,210.042,834.681,87.702,790,307.915" rect:frameRect];
```
To then render it as an `UIBezierPath` and/or `CAShapeLayer`:

```obj-c

    UIBezierPath *myPath = myBezier.bezier;
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

## Support
Please ask questions or raise issues in the [issues section](https://github.com/arielelkin/PocketSVG/issues)

## To Do

* Add support for parsing of whole SVG file (without having to copy-paste the contents of its d string"
* Generate NSBezierPaths as well as UIBezierPaths
* Fix warnings generated from NSLogs in SvgToBezier.m 

## License
[Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license] (http://creativecommons.org/licenses/by-sa/3.0)