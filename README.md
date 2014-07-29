# PocketSVG
A simple toolkit for reading SVG paths as CGPathRefs. Only the path element is supported.

[![Build Status](https://travis-ci.org/fjolnir/PocketSVG.svg?branch=master)](https://travis-ci.org/fjolnir/PocketSVG)

## Usage

```obj-c
    NSString *svgPath = [[NSBundle mainBundle] pathForResource:@"myImage" ofType:@"svg"];
    NSString *svgString = [NSString stringWithContentsOfFile:svgPath usedEncoding:NULL error:NULL];
    
    // Parse your SVG data
    for(id path in PSVGPathsFromSVGString(svgString, NULL)) {
        // Create a layer for each path
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = (__bridge CGPathRef)path;
        
        // Set its display properties
        layer.lineWidth   = 4;
        layer.strokeColor = [[UIColor blackColor] CGColor];
        layer.fillColor   = [[UIColor redColor] CGColor];
    
        // Add it to the layer hierarchy
        [self.view.layer addSublayer:layer];
    }
```


