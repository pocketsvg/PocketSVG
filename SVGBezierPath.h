#import "SVGPortability.h"

NS_ASSUME_NONNULL_BEGIN
@interface SVGBezierPath : SVGUI(BezierPath)
@property(nonatomic, readonly) NSDictionary<NSString*, id> *svgAttributes;
@property(nonatomic, readonly) NSString *SVGRepresentation;
#if !TARGET_OS_IPHONE
@property(nonatomic, readonly) CGPathRef CGPath;
#endif

+ (void)resetCache;

+ (NSArray<SVGBezierPath*> *)pathsFromSVGNamed:(NSString *)aName;
+ (NSArray<SVGBezierPath*> *)pathsFromSVGNamed:(NSString *)aName inBundle:(NSBundle *)bundle;
+ (NSArray<SVGBezierPath*> *)pathsFromContentsOfSVGFile:(NSString *)aPath;
+ (NSArray *)pathsFromSVGString:(NSString *)svgString;


#if !TARGET_OS_IPHONE
- (void)applyTransform:(CGAffineTransform)transform;
#endif
@end
NS_ASSUME_NONNULL_END