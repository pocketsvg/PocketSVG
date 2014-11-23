#import <TargetConditionals.h>

@class SVGImageView;

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@interface SVGViewController : UIViewController
@property(nonatomic, weak) IBOutlet SVGImageView *svgView;
@end

#else
#import <AppKit/AppKit.h>

@interface SVGViewController : NSViewController
@property(nonatomic, weak) IBOutlet SVGImageView *svgView;
@end
#endif
