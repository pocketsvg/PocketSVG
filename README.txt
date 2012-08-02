This is a fork of an SVG to bezier path parser by Martin Haywood.

LICENSE:
Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license 
http://creativecommons.org/licenses/by-sa/3.0

APPLE DOCS:
* http://developer.apple.com/library/ios/#documentation/uikit/reference/UIBezierPath_class/Reference/Reference.html
* https://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CAShapeLayer_class/Reference/Reference.html


INSTRUCTIONS:

1) Draw your bezier path in your favourite vector graphics app
2) Save as an SVG
3) Open the SVG file in your text editor, and copy the contents of the "d=" attribute.
4) To render it as an UIBezierPath and/or CAShapeLayer, see lines 20-33 of ViewController.m

TO DO:
* Generate NSBezierPaths as well as UIBezierPaths
* Fix warnings generated from NSLogs in SvgToBezier.m 
* Adapt SvgToBezier for ARC

See http://ponderwell.net/2011/05/converting-svg-paths-to-objective-c-paths/  for the original code.
