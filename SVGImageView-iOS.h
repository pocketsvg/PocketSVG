#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface SVGImageView : UIView
@property(nonatomic, copy) NSString *svgSource;
@property(nonatomic, copy) IBInspectable UIColor *fillColor, *strokeColor;
@end
