#import "SVGPortability.h"

IB_DESIGNABLE
@interface SVGImageView : PSVGView
@property(nonatomic, copy) IBInspectable NSString *svgName;
@property(nonatomic) IBInspectable BOOL scaleLineWidth;
@property(nonatomic, copy) NSString *svgSource;
@property(nonatomic, copy) IBInspectable PSVGColor *fillColor, *strokeColor;
+ (instancetype)imageViewWithSVGNamed:(NSString *)aSVGName;
@end
