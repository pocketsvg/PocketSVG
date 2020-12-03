/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGPortability.h"

NS_ASSUME_NONNULL_BEGIN

@class SVGBezierPath;

FOUNDATION_EXTERN CGRect SVGAdjustCGRectForContentsGravity(CGRect aRect, CGSize aSize, NSString *aGravity);
FOUNDATION_EXTERN CGRect SVGBoundingRectForPaths(NSArray<SVGBezierPath*> *paths);
FOUNDATION_EXTERN void SVGDrawPaths(NSArray<SVGBezierPath*> *paths, CGContextRef ctx, CGRect rect,
                                    __nullable CGColorRef defaultFillColor,
                                    __nullable CGColorRef defaultStrokeColor);
FOUNDATION_EXTERN void SVGDrawPathsWithBlock(NSArray<SVGBezierPath*> * const paths,
                                             CGContextRef const ctx,
                                             CGRect rect,
                                             void (^drawingBlock)(SVGBezierPath *path));

/// A NSBezierPath or UIBezierPath subclass that represents an SVG path
/// and its SVG attributes
@interface SVGBezierPath : PSVGBezierPath


/*!
 * @brief A set of paths and their attributes.
 *
 */
@property(nonatomic, readonly) NSDictionary<NSString*, id> *svgAttributes;


/*!
 * @brief The string representation of an SVG.
 *
 */
@property(nonatomic, readonly) NSString *SVGRepresentation;



/*!
 * @brief Returns an array of SVGBezierPaths given an SVG's URL.
 *
 * @param aURL The URL from which to load an SVG.
 *
 */
+ (NSArray<SVGBezierPath*> *)pathsFromSVGAtURL:(NSURL *)aURL;


/*!
 * @brief Returns an array of paths given the XML string of an SVG.
 *
 */
+ (NSArray<SVGBezierPath*> *)pathsFromSVGString:(NSString *)svgString;

/*!
 * @brief Returns a new path with the values of `attributes` added to `svgAttributes`
 *
 * @param attributes A dictionary of SVG attributes to set.
 *
 */
- (SVGBezierPath *)pathBySettingSVGAttributes:(NSDictionary *)attributes;

/*!
 * @brief The value of the SVG's viewBox attribute, expressed as a CGRect. If there is
 * no viewBox attribute, this property will be CGRect.null
 *
 */
@property(nonatomic, readonly) CGRect viewBox;

#if !TARGET_OS_IPHONE
@property(nonatomic, readonly) CGPathRef CGPath;
#endif


+ (void)resetCache;


#if !TARGET_OS_IPHONE
- (void)applyTransform:(CGAffineTransform)transform;
#endif
@end
NS_ASSUME_NONNULL_END

