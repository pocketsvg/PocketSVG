#import <TargetConditionals.h>

// This setup is just so Interface Builder doesn't get confused.
#if TARGET_OS_IPHONE
#   import "SVGImageView_iOS.h"
#else
#   import "SVGImageView_Mac.h"
#endif

@interface SVGImageView ()
@property(nonatomic, copy) IBInspectable NSString *svgName;
@property(nonatomic) IBInspectable BOOL scaleLineWidth;
+ (instancetype)imageViewWithSVGNamed:(NSString *)aSVGName;
@end
