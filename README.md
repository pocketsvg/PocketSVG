# SVGPathSerializing
A simple toolkit for reading reading/writing bezier paths to/from SVG. Only the path, polygon, & rectangle elements are supported.

The goal of this project is not to be a fully compatible SVG parser/renderer. But rather to use SVG as a format for serializing CG/UIPaths, meaning it only supports SVG features that can be represented by CG/UIPaths.

![Screenshot](http://d.asgeirsson.is/1ktx0.png)

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


