#import <AppKit/AppKit.h>

IB_DESIGNABLE
@interface SVGImageView : NSView
@property(nonatomic, copy) NSString *svgSource;
@property(nonatomic, copy) IBInspectable NSColor *fillColor, *strokeColor;
@end
