#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@interface SVGImageView : UIView
@property(nonatomic, copy) NSString *svgString, *svgFileName;
@property(nonatomic, copy) UIColor *fillColor, *strokeColor;

- (instancetype)initWithSVGNamed:(NSString *)aName
                       fillColor:(UIColor *)aFillColor
                     strokeColor:(UIColor *)aStrokeColor;
- (instancetype)initWithSVGString:(NSString *)aSVG
                        fillColor:(UIColor *)aFillColor
                      strokeColor:(UIColor *)aStrokeColor;
@end

#else
#import <AppKit/AppKit.h>

@interface SVGImageView : NSView
@property(nonatomic, copy) NSString *svgString, *svgFileName;
@property(nonatomic, copy) NSColor *fillColor, *strokeColor;

- (instancetype)initWithSVGNamed:(NSString *)aName
                       fillColor:(NSColor *)aFillColor
                     strokeColor:(NSColor *)aStrokeColor;
- (instancetype)initWithSVGString:(NSString *)aSVG
                        fillColor:(NSColor *)aFillColor
                      strokeColor:(NSColor *)aStrokeColor;
@end
#endif
