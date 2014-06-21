# PocketSVG
An Objective-C class that converts Scalable Vector Graphics (SVG) into CGPathRefs.
This makes it easy to create vector-based paths and shapes in your iOS or OS X apps. 

Feedback, improvements, and pull requests are welcome.

[![Build Status](https://travis-ci.org/arielelkin/PocketSVG.svg?branch=master)](https://travis-ci.org/arielelkin/PocketSVG)

## Usage
1. Make your drawing in a vector graphics editor such as Illustrator, Inkscape, [Sketch](http://www.bohemiancoding.com/sketch/), etc.
1. Save as an SVG.
1. Drag and drop it into your Xcode project.
1. Follow these easy steps:

```obj-c
    NSString *svgPath = [[NSBundle mainBundle] pathForResource:@"myImage" ofType:@"svg"];
    NSString *svgString = [NSString stringWithContentsOfFile:svgPath usedEncoding:NULL error:NULL];
    
    // 1: Turn your SVG into CGPathRefs:
    for(id path in PSVGPathsFromSVGString(svgString)) {
        // 2: To display a path on screen, you can create a CAShapeLayer:
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = (__bridge CGPathRef)path;
        
        // 3: Configure how it should be rendered
        layer.strokeColor = [[UIColor redColor] CGColor];
        layer.lineWidth   = 4;
        layer.fillColor   = [[UIColor clearColor] CGColor];
    
        // 4: Display it!
        [self.view.layer addSublayer:layer];
    }
```

## To Do
* Support for SVG's [Basic Shapes](http://www.w3.org/TR/SVG/shapes.html).

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
* [JagieChen](https://github.com/JagieChen)

## License

Copyright (c) 2013 Ponderwell, Ariel Elkin, and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

