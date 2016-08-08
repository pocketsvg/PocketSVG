#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
@compatibility_alias PSVGView UIView;
@compatibility_alias PSVGColor UIColor;
@compatibility_alias PSVGBezierPath UIBezierPath;

#else

#import <AppKit/AppKit.h>
@compatibility_alias PSVGView NSView;
@compatibility_alias PSVGColor NSColor;
@compatibility_alias PSVGBezierPath NSBezierPath;

#endif
