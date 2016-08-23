/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGPortability.h"

NS_ASSUME_NONNULL_BEGIN
@interface SVGBezierPath : PSVGBezierPath
@property(nonatomic, readonly) NSDictionary<NSString*, id> *svgAttributes;
@property(nonatomic, readonly) NSString *SVGRepresentation;
#if !TARGET_OS_IPHONE
@property(nonatomic, readonly) CGPathRef CGPath;
#endif

+ (void)resetCache;

+ (NSArray<SVGBezierPath*> *)pathsFromSVGNamed:(NSString *)aName;
+ (NSArray<SVGBezierPath*> *)pathsFromSVGNamed:(NSString *)aName inBundle:(NSBundle *)bundle;
+ (NSArray<SVGBezierPath*> *)pathsFromContentsOfSVGFile:(NSString *)aPath;
+ (NSArray<SVGBezierPath*> *)pathsFromSVGAtURL:(NSURL *)aURL;
+ (NSArray *)pathsFromSVGString:(NSString *)svgString;


#if !TARGET_OS_IPHONE
- (void)applyTransform:(CGAffineTransform)transform;
#endif
@end
NS_ASSUME_NONNULL_END