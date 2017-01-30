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

@implementation SVGImageView {
    SVGLayer *_svgLayer;
}

#if TARGET_OS_IPHONE
- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _svgLayer = (SVGLayer *)self.layer;
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _svgLayer = (SVGLayer *)self.layer;
    }
    return self;
}
#else
- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES;
        _svgLayer = [SVGLayer new];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.wantsLayer = YES;
        _svgLayer = [SVGLayer new];
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
    if (self = [self init]) {
        self.svgURL = url;
    }
    return self;
}


#if TARGET_OS_IPHONE
+ (Class)layerClass
{
    return [SVGLayer class];
}
#else
- (CALayer *)makeBackingLayer
{
    return _svgLayer;
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

- (NSString *)svgName { return _svgLayer.svgName; }
- (void)setSvgName:(NSString * const)aFileName { _svgLayer.svgName = aFileName; }

- (void)setSvgSource:(NSString * const)aSVG { [_svgLayer setSvgSource:aSVG]; }

- (NSURL *)svgURL                 { return _svgLayer.svgURL; }
- (void)setSvgURL:(NSURL *)svgURL { _svgLayer.svgURL = svgURL; }

- (PSVGColor *)fillColor { return _svgLayer.fillColor
                                  ? [PSVGColor colorWithCGColor:_svgLayer.fillColor]
                                  : nil; }
- (void)setFillColor:(PSVGColor * const)aColor { _svgLayer.fillColor = aColor.CGColor; }

- (PSVGColor *)strokeColor { return _svgLayer.strokeColor
                                    ? [PSVGColor colorWithCGColor:_svgLayer.strokeColor]
                                    : nil; }
- (void)setStrokeColor:(PSVGColor * const)aColor { _svgLayer.strokeColor = aColor.CGColor; }

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.layer.preferredFrameSize;
}
- (CGSize)intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}
@end
