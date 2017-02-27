# PocketSVG

[![CocoaPods](https://img.shields.io/cocoapods/p/PocketSVG.svg?maxAge=3601)](#) [![Build Status](https://travis-ci.org/pocketsvg/PocketSVG.svg?branch=master)](https://travis-ci.org/pocketsvg/PocketSVG) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Code Coverage](https://img.shields.io/cocoapods/metrics/doc-percent/PocketSVG.svg)](http://cocoadocs.org/docsets/PocketSVG)


A simple toolkit for displaying and manipulating SVGs on iOS and macOS in a performant manner.

The goal of this project is not to be a fully compliant SVG parser/renderer. But rather to use SVG as a format for serializing CG/UIPaths, meaning it only supports SVG features that can be represented by CG/UIPaths.

Thoroughly documented.

## Features

* Render SVG files via SVGImageView/Layer
* Display all kinds of SVGs shapes and paths.
* Fully working iOS and macOS demos.
* Straightforward API for typical SVG rendering (`SVGLayer` and `SVGImageView`)
* Supports more fine-grained SVG manipulation (`SVGBezierPath` and `SVGEngine`)


## Installation

### Cocoapods

Add `pod PocketSVG` to your Podfile.

### Carthage

Add this to your Cartfile:
```
github "pocketsvg/PocketSVG"
```

Then run `carthage update`.

### Manual

Drag and drop `PocketSVG.xcodeproj` into your Xcode project. In your project settings, add PocketSVG.framework in **Link Binary With Libraries**.


## Usage

Render an SVG file using SVGImageView:

```swift
let url = NSBundle.mainBundle().URLForResource("svg_file_name", withExtension: "svg")!
let svgImageView = SVGImageView(contentsOfURL: url)
view.addSubview(svgImageView)
```

Manually render each path of an SVG file into using CAShapeLayers:

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
