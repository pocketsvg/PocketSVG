# PocketSVG
A simple toolkit for reading SVG paths as CGPathRefs. Only the path element is supported.

[![Build Status](https://travis-ci.org/fjolnir/PocketSVG.svg?branch=master)](https://travis-ci.org/fjolnir/PocketSVG)

## Usage

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


