#import "SVGImageView.h"
#import "SVGLayer.h"
#import "SVGPortability.h"

@implementation SVGImageView

#if TARGET_OS_IPHONE
@dynamic fillColor, strokeColor, svgFileName, svgString;

+ (Class)layerClass
{
    return [SVGLayer class];
}
#else
- (CALayer *)makeBackingLayer
{
    SVGLayer * const layer = [SVGLayer new];
    layer.fillColor   = _fillColor.CGColor;
    layer.strokeColor = _strokeColor.CGColor;
    if(_svgFileName)
        layer.svgFileName = _svgFileName;
    else if(_svgString)
        layer.svgString = _svgString;
    return layer;
}
- (BOOL)isFlipped
{
    return YES;
}
- (void)sizeToFit
{
    self.bounds = (NSRect) { self.bounds.origin, [self sizeThatFits:CGSizeZero] };
}
#endif

- (SVGLayer *)_svgLayer { return (id)self.layer; }

- (void)setSvgString:(NSString * const)aSVG {
#if !TARGET_OS_IPHONE
    _svgString = aSVG;
#endif
    self._svgLayer.svgString = aSVG;
}
- (void)setSvgFileName:(NSString * const)aFileName {
#if !TARGET_OS_IPHONE
    _svgFileName = aFileName;
#endif
    self._svgLayer.svgFileName = aFileName;
}
- (void)setFillColor:(SVGUI(Color) * const)aColor {
#if !TARGET_OS_IPHONE
    _fillColor = aColor;
#endif
    self._svgLayer.fillColor = aColor.CGColor;
}
- (void)setStrokeColor:(SVGUI(Color) * const)aColor {
#if !TARGET_OS_IPHONE
    _strokeColor = aColor;
#endif
    self._svgLayer.strokeColor = aColor.CGColor;
}

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.layer.preferredFrameSize;
}

@end
