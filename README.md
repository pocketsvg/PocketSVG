# SVGPathSerializer
A simple toolkit for reading reading/writing bezier paths to/from SVG. Only the path, polygon, & rectangle elements are supported.

This project started as a fork of Ariel Elkin's PocketSVG.

## Basic Usage

```obj-c
    NSString *svgPath = [[NSBundle mainBundle] pathForResource:@"myImage" ofType:@"svg"];
    NSString *svgString = [NSString stringWithContentsOfFile:svgPath usedEncoding:NULL error:NULL];
    
    // Parse your SVG data
    for(id path in CGPathsFromSVGString(svgString, NULL)) {
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


