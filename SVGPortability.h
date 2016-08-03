#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#   import <UIKit/UIKit.h>
#   define View UIView
#   define Color UIColor
#   define BezierPath UIBezierPath
#else
#   import <AppKit/AppKit.h>
#   define View NSView
#   define Color NSColor
#   define BezierPath NSBezierPath
#endif
