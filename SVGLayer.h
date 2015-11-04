#import <QuartzCore/QuartzCore.h>

@interface SVGLayer : CALayer
@property(nonatomic, copy) NSString *svgSource;
@property(nonatomic) CGColorRef fillColor, strokeColor;
@property(nonatomic) BOOL scaleLineWidth;

- (void)loadSVGNamed:(NSString *)aName;
@end
