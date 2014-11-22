#import "SVGImageView.h"
#import "SVGLayer.h"

@interface SVGImageView ()
@property(nonatomic, readonly) SVGLayer *svgLayer;
@end

@implementation SVGImageView
@dynamic fillColor, strokeColor, svgFileName, svgString;

+ (Class)layerClass
{
    return [SVGLayer class];
}
- (SVGLayer *)svgLayer
{
    return (SVGLayer *)self.layer;
}

- (instancetype)initWithSVGNamed:(NSString * const)aName
                       fillColor:(UIColor * const)aFillColor
                     strokeColor:(UIColor * const)aStrokeColor
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
                        fillColor:(UIColor * const)aFillColor
                      strokeColor:(UIColor * const)aStrokeColor
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

- (void)setFillColor:(UIColor * const)aColor { self.svgLayer.fillColor = aColor.CGColor; }
- (UIColor *)fillColor { return [UIColor colorWithCGColor:self.svgLayer.fillColor]; }

- (void)setStrokeColor:(UIColor * const)aColor { self.svgLayer.strokeColor = aColor.CGColor; }
- (UIColor *)strokeColor { return [UIColor colorWithCGColor:self.svgLayer.strokeColor]; }

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.svgLayer.preferredFrameSize;
}

@end
