#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface SVGImageView : UIView
@property(nonatomic, copy) IBInspectable NSString *svgString, *svgFileName;
@property(nonatomic, copy) IBInspectable UIColor *fillColor, *strokeColor;
@end
