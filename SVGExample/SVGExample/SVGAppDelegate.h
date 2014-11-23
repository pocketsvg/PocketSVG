#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@interface SVGAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

#else
#import <Cocoa/Cocoa.h>
@class SVGImageView;

@interface SVGAppDelegate : NSObject <NSApplicationDelegate>
@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet SVGImageView *svgView;
@end
#endif
