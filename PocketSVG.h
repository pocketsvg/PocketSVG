#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class SVGAttributeSet;

#ifdef __cplusplus
extern "C" {
#endif

/*!
 *  Returns an array of CGPathRefs contained within the passed SVG string.
 *
 *  @param svgString The string containing the SVG formatted path.
 *  @param attributes An optional pointer for storing a map table containing SVG attributes for the paths
 *
 *  @return An array of CGPathRef objects or nil if none are found
 */
NSArray *CGPathsFromSVGString(NSString *svgString, SVGAttributeSet **attributes);


/*!
 *  Returns SVG representing `paths`
 *
 *  @param paths An array of CGPathRefs to construct the SVG from
 *  @param attributes An optional map table of SVG attributes for the paths
 *
 *  @return SVG representing `paths`
 */
NSString *SVGStringFromCGPaths(NSArray *paths, SVGAttributeSet *attributes);

@interface SVGAttributeSet : NSObject <NSCopying, NSMutableCopying>
- (NSDictionary<NSString*,id> *)attributesForPath:(CGPathRef)path;
@end
@interface SVGMutableAttributeSet : SVGAttributeSet
- (void)setAttributes:(NSDictionary<NSString*,id> *)attributes forPath:(CGPathRef)path;
@end
    
@interface NSValue (PocketSVG)
+ (instancetype)svg_valueWithCGAffineTransform:(CGAffineTransform)aTransform;
- (CGAffineTransform)svg_CGAffineTransformValue;
@end

#import "SVGBezierPath.h"
#import "SVGImageView.h"
#import "SVGLayer.h"

#ifdef __cplusplus
};
#endif
