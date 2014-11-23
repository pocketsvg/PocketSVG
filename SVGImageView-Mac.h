#import <AppKit/AppKit.h>

IB_DESIGNABLE
@interface SVGImageView : NSView
@property(nonatomic, copy) IBInspectable NSString *svgString, *svgFileName;
@property(nonatomic, copy) IBInspectable NSColor *fillColor, *strokeColor;
@end
