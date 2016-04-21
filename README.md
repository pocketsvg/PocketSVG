# SVGPathSerializing
A simple toolkit for reading reading/writing bezier paths to/from SVG. Only the path, polygon, & rectangle elements are supported.

The goal of this project is not to be a fully compatible SVG parser/renderer. But rather to use SVG as a format for serializing CG/UIPaths, meaning it only supports SVG features that can be represented by CG/UIPaths.

![Screenshot](http://d.asgeirsson.is/1ktx0.png)

## Basic Usage

(Note: If you just want to display an SVG, using SVGImageView is much easier, and it'll render the SVG within Interface Builder as well)

```obj-c
    for(SVGBezierPath *path in [SVGBezierPath pathsFromSVGNamed:@"myImage"]) {
        // Create a layer for each path
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        
        // Set its display properties
        layer.lineWidth   = 4;
        layer.strokeColor = [path.svgAttributes[@"stroke"] ?: [UIColor blackColor] CGColor];
        layer.fillColor   = [path.svgAttributes[@"fill"] ?: [UIColor redColor] CGColor];
    
        // Add it to the layer hierarchy
        [self.view.layer addSublayer:layer];
    }
```


