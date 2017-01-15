/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGImageView.h"
#import "SVGLayer.h"
#import "SVGPortability.h"

@implementation SVGImageView
#if TARGET_OS_OSX
- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES;
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.wantsLayer = YES;
    }
    return self;
}
#endif

- (instancetype)initWithSVGSource:(NSString *)svgSource {
    if (self = [self init]) {
        self.svgSource = svgSource;
    }
    return self;
}


- (instancetype)initWithContentsOfURL:(NSURL *)url {

    NSString *svgSource = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];

    return [self initWithSVGSource:svgSource];
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
    if (_svgSource) {
        layer.svgSource = _svgSource;
    }
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
- (void)setSvgURL:(NSURL *)svgURL {
    NSString *aSVG = [NSString stringWithContentsOfURL:svgURL encoding:NSUTF8StringEncoding error:nil];
    _svgSource = aSVG;
    self._svgLayer.svgSource = aSVG;
}
- (void)setFillColor:(PSVGColor * const)aColor {
    _fillColor = aColor;
    self._svgLayer.fillColor = aColor.CGColor;
}
- (void)setStrokeColor:(PSVGColor * const)aColor {
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
