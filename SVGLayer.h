#import <QuartzCore/QuartzCore.h>

@interface SVGLayer : CALayer
@property(nonatomic, copy) NSString *svgString, *svgFileName;
@property(nonatomic) CGColorRef fillColor, strokeColor;
@end
