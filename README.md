# PocketSVG

[![Build Status](https://travis-ci.org/arielelkin/PocketSVG.svg?branch=master)](https://travis-ci.org/arielelkin/PocketSVG)

A simple toolkit for displaying and manipulating SVGs on iOS and macOS. 

Convert your SVGs into 

* `UIView`
* `NSView`
* `CGPath`
* `CALayer`
* `UIBezierPath`
* `NSBezierPath`

Thoroughly documented. 

## Features

* Turn your SVG into an UIView/NSView 
* Turn your SVG into a CALayer
* Display all kinds of SVGs shapes and paths.
* Fully working iOS and macOS demos.
* Straightforward API for typical SVG rendering (`SVGLayer` and `SVGImageView`) 
* Supports more fine-grained SVG manipulation (`SVGBezierPath` and `SVGEngine`)


## Installation

### Cocoapods

Add `pod PocketSVG` to your Podfile. 

### Manual

Drag and drop `PocketSVG.xcodeproj` into your Xcode project. In your project settings, add PocketSVG.framework in **Link Binary With Libraries**.


## Usage

Render an SVG file into a UIView:

```swift
let url = NSBundle.mainBundle().URLForResource("svg_file_name", withExtension: "svg")!
let svgImageView = SVGImageView(contentsOfURL: url)
view.addSubview(svgImageView)
```

Render an SVG file into an NSView:

```
let svgImageView = SVGImageView(SVGNamed: "svg_file_name")
view.addSubview(svgImageView)
```

Render each path of an SVG file into its own CALayer:


```objective-c
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

## Screenshots

### iOS

![iOS Screenshot](http://i.imgur.com/tD3oc04.png)

### macOS

![macOS Screenshot](http://i.imgur.com/7tY8Suw.png)


## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/arielelkin/pocketsvg/issues) to report any bugs or file feature requests.

### Developing

PRs are welcome. 
