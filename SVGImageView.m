#import "SVGImageView.h"
#import "SVGLayer.h"
#import "SVGPortability.h"

@implementation SVGImageView

+ (instancetype)imageViewWithSVGNamed:(NSString *)aSVGName
{
    SVGImageView * const view = [self new];
    view.svgName = aSVGName;
    [view sizeToFit];
    return view;
}

#if TARGET_OS_IPHONE
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
    if(_svgName)
        [layer loadSVGNamed:_svgName];
    else if(_svgSource)
        layer.svgSource = _svgSource;
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

- (void)setSvgSource:(NSString * const)aSVG {
    _svgSource = aSVG;
    self._svgLayer.svgSource = aSVG;
}
- (void)setSvgName:(NSString * const)aName {
    _svgName = aName;
    [self._svgLayer loadSVGNamed:_svgName];
}
- (void)setFillColor:(Color * const)aColor {
    _fillColor = aColor;
    self._svgLayer.fillColor = aColor.CGColor;
}
- (void)setStrokeColor:(Color * const)aColor {
    _strokeColor = aColor;
    self._svgLayer.strokeColor = aColor.CGColor;
}

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.layer.preferredFrameSize;
}
- (CGSize)intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}

@end
