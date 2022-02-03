# PocketSVG

[![Platforms](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS-green?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS-green?style=flat-square)
[![Build Status](https://github.com/pocketsvg/pocketsvg/workflows/CI/badge.svg)](https://github.com/pocketsvg/PocketSVG/actions) 
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PocketSVG.svg)](https://cocoapods.org/pods/PocketSVG) 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) 
[![Code Coverage](https://img.shields.io/cocoapods/metrics/doc-percent/PocketSVG.svg)](http://cocoadocs.org/docsets/PocketSVG) 
[![code size](https://img.shields.io/github/languages/code-size/pocketsvg/pocketsvg.svg)](#) 
[![license](https://img.shields.io/github/license/pocketsvg/pocketsvg.svg)](https://github.com/pocketsvg/PocketSVG/blob/master/LICENSE)
[![Swift Forums](https://img.shields.io/badge/Swift_Forums-PocketSVG-orange?style=flat-square)](https://youtu.be/iik25wqIuFo)


A simple toolkit for displaying and manipulating SVGs on iOS and macOS in a performant manner.

The goal of this project is not to be a fully compliant SVG parser/renderer. But rather to use SVG as a format for serializing CG/UIPaths, meaning it only supports SVG features that can be represented by CG/UIPaths.

Thoroughly documented.

## Features

* Support for SVG elements: `path`, `line`, `polyline`, `polygon`, `rect`, `circle`, `ellipse`
* Support for SVG named colors.
* Fully working iOS and macOS demos.
* Straightforward API for typical SVG rendering as a `UIImageView`/`NSImageView` or `CALayer` subclass.
* Access every shape within your SVG as a `CGPath` for more fine-grained manipulation.


## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/pocketsvg/PocketSVG.git", .upToNextMajor(from: "2.6.0"))
]
```

### Cocoapods

Add this to your Podfile:
```ruby
pod 'PocketSVG', '~> 2.6'
```

Then run `pod install`

### Carthage

Add this to your Cartfile:
```
github "pocketsvg/PocketSVG" >= 2.7.2
```

Then run `carthage update --use-xcframeworks`

## Usage

### Render an SVG file using `SVGImageView`

```swift
let url = Bundle.main.url(forResource: "tiger", withExtension: "svg")!
let svgImageView = SVGImageView.init(contentsOf: url)
svgImageView.frame = view.bounds
svgImageView.contentMode = .scaleAspectFit
view.addSubview(svgImageView)
```

**Output**
![image](https://user-images.githubusercontent.com/1756909/38315263-6664fe64-3828-11e8-8d49-1e0c52f3d4e2.png)

Note: By default, SVGLayer has `shouldRasterize` set to `YES` when running on iOS. If you need to animate changes to the layer's transform you might want to reset that to `NO`.


### Manually render each path of an SVG file using `CAShapeLayer`

```swift
view.backgroundColor = .white

let svgURL = Bundle.main.url(forResource: "tiger", withExtension: "svg")!
let paths = SVGBezierPath.pathsFromSVG(at: svgURL)
let tigerLayer = CALayer()
for (index, path) in paths.enumerated() {
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path.cgPath
    if index%2 == 0 {
        shapeLayer.fillColor = UIColor.black.cgColor
    }
    else if index%3 == 0 {
        shapeLayer.fillColor = UIColor.darkGray.cgColor
    }
    else {
        shapeLayer.fillColor = UIColor.gray.cgColor
    }
    tigerLayer.addSublayer(shapeLayer)
}

var transform = CATransform3DMakeScale(0.4, 0.4, 1.0)
transform = CATransform3DTranslate(transform, 200, 400, 0)
tigerLayer.transform = transform
view.layer.addSublayer(tigerLayer)
```

**Output**
![image](https://user-images.githubusercontent.com/1756909/38315982-f3f7017c-3829-11e8-9c7f-420eb15e727e.png)

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/arielelkin/pocketsvg/issues) to report any bugs or file feature requests.

### Developing

PRs are welcome.
