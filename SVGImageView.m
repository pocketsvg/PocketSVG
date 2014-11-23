#import "SVGImageView.h"
#import "SVGLayer.h"
#import "SVGPortability.h"

@interface SVGImageView ()
@property(nonatomic, readonly) SVGLayer *svgLayer;
@end

@implementation SVGImageView
@dynamic fillColor, strokeColor, svgFileName, svgString, svgLayer;

#if TARGET_OS_IPHONE
+ (Class)layerClass
{
    return [SVGLayer class];
}
#else
- (CALayer *)makeBackingLayer
{
    return [SVGLayer new];
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

- (SVGLayer *)svgLayer
{
    return (SVGLayer *)self.layer;
}

- (instancetype)initWithSVGNamed:(NSString * const)aName
                       fillColor:(SVGUI(Color) * const)aFillColor
                     strokeColor:(SVGUI(Color) * const)aStrokeColor
{
    if((self = [self init])) {
        self.fillColor   = aFillColor;
        self.strokeColor = aStrokeColor;
        self.svgFileName = aName;

        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithSVGString:(NSString * const)aSVG
                        fillColor:(SVGUI(Color) * const)aFillColor
                      strokeColor:(SVGUI(Color) * const)aStrokeColor
{
    if((self = [self init])) {
        self.fillColor   = aFillColor;
        self.strokeColor = aStrokeColor;
        self.svgString   = aSVG;

        [self sizeToFit];
    }
    return self;
}

- (void)setSvgString:(NSString * const)aSVG { self.svgLayer.svgString = aSVG; }
- (NSString *)svgString { return self.svgLayer.svgString; }

- (void)setSvgFileName:(NSString * const)aFileName { self.svgLayer.svgFileName = aFileName; }
- (NSString *)svgFileName { return self.svgLayer.svgFileName; }

- (void)setFillColor:(SVGUI(Color) * const)aColor { self.svgLayer.fillColor = aColor.CGColor; }
- (SVGUI(Color) *)fillColor { return [SVGUI(Color) colorWithCGColor:self.svgLayer.fillColor]; }

- (void)setStrokeColor:(SVGUI(Color) * const)aColor { self.svgLayer.strokeColor = aColor.CGColor; }
- (SVGUI(Color) *)strokeColor { return [SVGUI(Color) colorWithCGColor:self.svgLayer.strokeColor]; }

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.svgLayer.preferredFrameSize;
}

@end
