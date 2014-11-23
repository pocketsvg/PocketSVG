#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#   import <UIKit/UIKit.h>
#   define SVGUI(kls) UI##kls
#else
#   import <AppKit/AppKit.h>
#   define SVGUI(kls) NS##kls
#endif
