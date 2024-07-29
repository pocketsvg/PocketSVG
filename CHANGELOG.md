# Changelog
All notable changes to this project will be documented in this file. Items under **Unreleased** are currently available on **master**'s HEAD, but not yet tagged.

## [Unreleased]
### Fixes

## [2.7.3]
### Fixes
- Support for shortcuts with leading zeros as described in issue (https://github.com/pocketsvg/PocketSVG/issues/204) [Vladimir Roganov](https://github.com/elisar4) [#205](https://github.com/pocketsvg/PocketSVG/pull/205)

- Prevents the program from crashing when the color passed in is not of the correct type [CodeForRabbit](https://github.com/CodeForRabbit) [#214](https://github.com/pocketsvg/PocketSVG/pull/214)

## [2.7.2]
### Fixes
- Find named colour tags plist when using SPM.

## [2.7.1]
### Fixes
- Address Xcode 13 related warnings. [Sergio Baró](https://www.github.com/sergiobaro) [#195](https://github.com/pocketsvg/PocketSVG/pull/195)

## [2.7.0]
### New Features
- Support for `viewBox` tag. [Alessio Prosperi](https://github.com/NeedNap)
 and [Ariel Elkin](https://github.com/arielelkin) [#181](https://github.com/pocketsvg/PocketSVG/pull/181) and [#185](https://github.com/pocketsvg/PocketSVG/pull/185).

## [2.6.0]
### New Features
- Xcode 12 and SPM Support. [Ariel Elkin](https://github.com/arielelkin), [#178](https://github.com/pocketsvg/PocketSVG/pull/178/)
- New API method for clients to convert single path string into CGPath. [Scott Sykora
](https://github.com/scottsykora), [#172](https://github.com/pocketsvg/PocketSVG/pull/172) 

### Fixes
- Removed redundant "CGPathGetCurrentPoint: no current point" log statements. [Yoni Levy](https://github.com/yonilevy), [#173](https://github.com/pocketsvg/PocketSVG/pull/173)

## [2.5.0]
### New Features
- Support <line> tags. Sebastian Ludwig, [#154](https://github.com/pocketsvg/PocketSVG/pull/154)
- Support stroke attributes `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit` and `stroke-dasharray`. Sebastian Ludwig [#154](https://github.com/pocketsvg/PocketSVG/pull/154)
- Added support for elliptical arc commands sequence of after a single "a". Vladimir Roganov [#143](https://github.com/pocketsvg/PocketSVG/pull/143)
- Xcode 11 support

### Fixes
- Fix for OS X Crash (https://github.com/pocketsvg/PocketSVG/issues/136) via [Gabor Nemeth](https://github.com/gabor-nemeth)
- Fix 1pt line scaling. Sebastian Ludwig [#159](https://github.com/pocketsvg/PocketSVG/pull/159)
- Fix named SVG Colors. After code refactor made on commit feafc5f SVGColors plist file was renamed but this were not reflected on plist loading code. [Daniel Coello](https://github.com/danicoello)
- Fixed Xcode 11 build (https://github.com/pocketsvg/PocketSVG/issues/163) by treating SVGColors.plist as a resource instead of a source file. Chris Vasselli [#168](https://github.com/pocketsvg/PocketSVG/pull/168)

## [2.4.2]
### Fixes
- Fix iOS12 regression on pathsFromSVGString. Noah Gilmore. [#128](https://github.com/pocketsvg/PocketSVG/issues/128) via [#133](https://github.com/pocketsvg/PocketSVG/pull/133).

### Internal Changes
- Embed Iceland SVG example in a zoomable scroll view. kwabford. [#137](https://github.com/pocketsvg/PocketSVG/pull/137)

## [2.4.1]
### Fixes
- Add support for integer function SVG colors: rgb(int, int, int). Clément Beffa [#124](https://github.com/pocketsvg/PocketSVG/pull/124)

### Internal Changes
- Add unit tests. Ariel Elkin.
- Handle attributes on `<a>` elements and ignore unknown elements. Scott Talbot [#121](https://github.com/pocketsvg/PocketSVG/pull/121)
- Demo project: show Icelandic SVG in scrollview. Kwab Fordjour [#137](https://github.com/pocketsvg/PocketSVG/pull/137)

## [2.4.0]
### New Features
- Add support for named SVG colors. Jonnie Walker [#119](https://github.com/pocketsvg/PocketSVG/pull/119)
- Add CHANGELOG. Ariel Elkin [feafc5fb9142a9e7f28581f9bd464636bad614cb](https://github.com/pocketsvg/PocketSVG/commit/feafc5fb9142a9e7f28581f9bd464636bad614cb)
- Update iOS Demo projects. Ariel Elkin [feafc5fb9142a9e7f28581f9bd464636bad614cb](https://github.com/pocketsvg/PocketSVG/commit/feafc5fb9142a9e7f28581f9bd464636bad614cb)

### Fixes
- Apply nested transformations in the correct order. Scott Talbot [#117](https://github.com/pocketsvg/PocketSVG/pull/117)
- Rounded Rectangles & Ellipses Can Specify either or `rx` `ry`. Previously a missing attribute was interpreted as 0, whereas the spec says it should be equal to the one that is supplied. Johnnie Walker [#120](https://github.com/pocketsvg/PocketSVG/pull/120)


## [2.3.1] 2018-03-21
### New Features
- Use `CGPathAddRoundedRect` to generate Rectangle, support rx/ry in rect element. George Maisuradze [#92](https://github.com/pocketsvg/PocketSVG/pull/92)

## [2.3.0] 2018-03-21
### New Features
- Implement elliptical arc command. Yaroslav Ponomarenko [#114](https://github.com/pocketsvg/PocketSVG/pull/114)
- Added API for drawing via CoreGraphics. Fjölnir Ásgeirsson [fb4c17bc621f707ee40deff3aec46826a9ec0c4b](https://github.com/pocketsvg/PocketSVG/commit/fb4c17bc621f707ee40deff3aec46826a9ec0c4b)
- Add `SVGDrawPathsWithBlock`. Fjölnir Ásgeirsson [7aba0fa2d580cfae351c11ddd327e5af91832bff](https://github.com/pocketsvg/PocketSVG/commit/7aba0fa2d580cfae351c11ddd327e5af91832bff)
- Add support for `<polyline>`. Fjölnir Ásgeirsson [ab272c75ab66650f319e1f6be0844fa25a00332d](https://github.com/pocketsvg/PocketSVG/commit/ab272c75ab66650f319e1f6be0844fa25a00332d)

### Fixes
- Fixed incorrect transform. Florent Pillet [#90](https://github.com/pocketsvg/PocketSVG/pull/90)
- Retain `CGColorRefs` for non-default colours. [#115](https://github.com/pocketsvg/PocketSVG/pull/115)
- Documentation issues. Noah Gilmore [efb22b9f31d84eefb8f34355e40bcf15c8d68d4f](https://github.com/pocketsvg/PocketSVG/commit/efb22b9f31d84eefb8f34355e40bcf15c8d68d4f)
- Bug when `_attributes` was nil. AceSha [#103](https://github.com/pocketsvg/PocketSVG/pull/103)
- Make CODE_SIGN_STYLE = Automatic. Anders Back [#106](https://github.com/pocketsvg/PocketSVG/pull/106)
- Use svgAttributes when generating SVGRepresentation for SVGBezierPath. Michał Ciuba [#113](https://github.com/pocketsvg/PocketSVG/pull/113)

### Internal Changes
- Made framework specify extension safety. Fjölnir Ásgeirsson (69eebdd60186f8b312bd62ec94c6740d4f60ff4c)[https://github.com/pocketsvg/PocketSVG/commit/69eebdd60186f8b312bd62ec94c6740d4f60ff4c]


## [2.2.1] 2017-03-30
### Fixes
- Broken initialization. Fjölnir Ásgeirsson [41ef1b6fef1178ac4f0e54c7dbb6db6a72deb935](https://github.com/pocketsvg/PocketSVG/commit/41ef1b6fef1178ac4f0e54c7dbb6db6a72deb935)


## [2.2.0] - 2017-02-27
### New Features
- Made svgNamed use urlForResource. Fjölnir Ásgeirsson [49f926ccd0781d22b52ab26fb18541a57b70bf57](https://github.com/pocketsvg/PocketSVG/commit/49f926ccd0781d22b52ab26fb18541a57b70bf57)

### Fixes
- Unbroke SVGBezierPath file cache. Fjölnir Ásgeirsson [b1353a156ef432d100f0ba29878dbdbc3ee752d1](https://github.com/pocketsvg/PocketSVG/commit/b1353a156ef432d100f0ba29878dbdbc3ee752d1)

## [2.1.1] - 2017-01-15
### Fixes
- add stc++ to podspec required libs


## [2.1.0] - 2017-01-15
### New Features
- Support for parsing ellipses. Sam Corder [#76](https://github.com/pocketsvg/PocketSVG/pull/76)


## [2.1.0] - 2017-01-15
### New Features
- Support for parsing ellipses. Sam Corder [#76](https://github.com/pocketsvg/PocketSVG/pull/76)

### Fixes
- missing initializer, missing `setSvgURL` method to clear contents and render a new SVG given the URL of the SVG, support for "fill-rule" tag, support for rotating around a point. Dunja Lalic [#67](https://github.com/pocketsvg/PocketSVG/pull/67)


## [2.0.0] - 2016-10-06
Major refactor by Fjölnir Ásgeirsson to improve parser efficiency and support more SVG operations: https://github.com/pocketsvg/PocketSVG/pull/47
### New Features
- `SVGLayer`, `SVGBezierPath`, `SVGEngine`, `SVGImageView`, `SVGPortability` (replaces `PocketSVG` class.)


## [0.7] - 2015-11-05
### New Features
- Travis CI to check if project builds properly. Ariel Elkin.
- Support for Carthage. Johan T. Halseth [1c45b8b1f159e1b9467afe4cde05a670f4c5ee33](https://github.com/pocketsvg/PocketSVG/commit/1c45b8b1f159e1b9467afe4cde05a670f4c5ee33)
- dynamic Interface Builder compatibility. Nathan F Johnson [#36](https://github.com/pocketsvg/PocketSVG/pull/36)
- Support Quadratic Bézier paths. Daniel Worku [#34](https://github.com/pocketsvg/PocketSVG/pull/34)
- add OS X deployment target to podspec. iamdoron [#31](https://github.com/pocketsvg/PocketSVG/pull/31)

### Fixes
- SVG rendering bug. Haris Amin hamin [#35](https://github.com/pocketsvg/PocketSVG/pull/35)


## [0.6] - 2014-03-06
### New Features
- `pathFromSVGString` and `pathFromDAttribute` factory methods. Daniel Schlaug [#22](https://github.com/pocketsvg/PocketSVG/pull/22)


## [0.5] - 2014-02-11
Changes by Ariel Elkin unless otherwise specified.

### New Features
- Add files from [Martin Haywood's SVG to bezier path parser](http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/)
- README file with usage instructions.
- .gitignore
- Demo code and files.
- `initFromSVGFileNamed` method.
- Improved error handling.
- Improved OSX compatibility. mcianni [#4](https://github.com/pocketsvg/PocketSVG/pull/4)
- Support for SVG files exported by Sketch. JagieChen [#14](https://github.com/pocketsvg/PocketSVG/pull/14)
- Support for Cocoapods (add LICENSE file and podspec). Boris Bügling [#16](https://github.com/pocketsvg/PocketSVG/pull/16)
- Init from file URL. Jorge Mendez [#19](https://github.com/pocketsvg/PocketSVG/pull/19)

### Fixes
- Parsing bugs. Pieter Omvlee [122994696c2f2936c30cf67fa62c0ea1fb2a5a79](https://github.com/pocketsvg/PocketSVG/commit/5d8a88c74af0654743d6395c48f83a0e9305479a)
- Distortion of aspect ratio. Dominic Mortlock [676507cbafe27c77e8ac74b6da42324c73acdbe1](https://github.com/pocketsvg/PocketSVG/commit/676507cbafe27c77e8ac74b6da42324c73acdbe1)

### Internal Changes
- File headers to include license information.
- Converted Martin's parser to ARC.
- Substituted CC license with MIT license.


[Unreleased]: https://github.com/pocketsvg/PocketSVG/compare/2.7.3...HEAD
[2.7.3]: https://github.com/pocketsvg/PocketSVG/compare/2.7.2...2.7.3
[2.7.2]: https://github.com/pocketsvg/PocketSVG/compare/2.7.1...2.7.2
[2.7.1]: https://github.com/pocketsvg/PocketSVG/compare/2.7.0...2.7.1
[2.7.0]: https://github.com/pocketsvg/PocketSVG/compare/2.6.0...2.7.0
[2.6.0]: https://github.com/pocketsvg/PocketSVG/compare/2.5.0...2.6.0
[2.5.0]: https://github.com/pocketsvg/PocketSVG/compare/2.4.2...2.5.0
[2.4.2]: https://github.com/pocketsvg/PocketSVG/compare/2.4.1...2.4.2
[2.4.1]: https://github.com/pocketsvg/PocketSVG/compare/2.4.0...2.4.1
[2.4.0]: https://github.com/pocketsvg/PocketSVG/compare/2.3.1...2.4.0
[2.3.1]: https://github.com/pocketsvg/PocketSVG/compare/2.3.0...2.3.1
[2.3.0]: https://github.com/pocketsvg/PocketSVG/compare/2.2.1...2.3.0
[2.2.1]: https://github.com/pocketsvg/PocketSVG/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/pocketsvg/PocketSVG/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/pocketsvg/PocketSVG/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/pocketsvg/PocketSVG/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/pocketsvg/PocketSVG/compare/0.7...2.0.0
[0.7]: https://github.com/pocketsvg/PocketSVG/compare/0.6...0.7
[0.6]: https://github.com/pocketsvg/PocketSVG/compare/0.5...0.6
[0.5]: https://github.com/pocketsvg/PocketSVG/compare/152270715237eebd9c11699c2aba8078f12ce41c...0.5
