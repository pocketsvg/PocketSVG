/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

@class SVGAttributeSet;


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

#ifdef __cplusplus
};
#endif
