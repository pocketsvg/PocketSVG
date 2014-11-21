#import <UIKit/UIKit.h>

@interface SVGImageView : UIView
@property(nonatomic, copy) NSString *svgString, *svgFileName;
@property(nonatomic, copy) UIColor *fillColor, *strokeColor;

- (instancetype)initWithSVGNamed:(NSString *)aName
                       fillColor:(UIColor *)aFillColor
                     strokeColor:(UIColor *)aStrokeColor;
- (instancetype)initWithSVGString:(NSString *)aSVG
                        fillColor:(UIColor *)aFillColor
                      strokeColor:(UIColor *)aStrokeColor;
@end
