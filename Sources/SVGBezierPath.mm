/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGBezierPath.h"
#import "SVGEngine.h"


@implementation SVGBezierPath
#if !TARGET_OS_IPHONE
{
    CGAffineTransform _cgTransformBuffer;
}
@synthesize CGPath=_CGPath;

- (instancetype)init
{
    if ((self = [super init])) {
        _cgTransformBuffer = CGAffineTransformIdentity;
    }
    return self;
}
#endif

+ (NSCache<NSURL*, NSArray<SVGBezierPath*>*> *)_svg_pathCache
{
    static NSCache<NSURL*, NSArray<SVGBezierPath*>*> *pathCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pathCache = [NSCache new];
    });
    return pathCache;
}
+ (void)resetCache
{
    [self._svg_pathCache removeAllObjects];
}

+ (NSArray<SVGBezierPath*> *)pathsFromSVGAtURL:(NSURL *)aURL
{
    NSArray<SVGBezierPath*> *paths = [self.class._svg_pathCache objectForKey:aURL];
    if (!paths) {
        paths =  [self pathsFromSVGString:[NSString stringWithContentsOfURL:aURL
                                                               usedEncoding:NULL
                                                                      error:NULL]];
        if (paths) {
            [self.class._svg_pathCache setObject:paths forKey:aURL];
        }
    }
    return [[NSArray alloc] initWithArray:paths copyItems:YES];
}

+ (NSArray<SVGBezierPath*> *)pathsFromSVGString:(NSString * const)svgString
{
    SVGAttributeSet *cgAttrs;
    NSArray * const pathRefs = CGPathsFromSVGString(svgString, &cgAttrs);
    NSMutableArray<SVGBezierPath*> * const paths = [NSMutableArray arrayWithCapacity:pathRefs.count];
    for(id pathRef in pathRefs) {
        SVGBezierPath * const uiPath = [self bezierPathWithCGPath:(__bridge CGPathRef)pathRef];
        uiPath->_svgAttributes = [cgAttrs attributesForPath:(__bridge CGPathRef)pathRef] ?: @{};
        uiPath.lineWidth = uiPath->_svgAttributes[@"stroke-width"] ? [uiPath->_svgAttributes[@"stroke-width"] doubleValue] : 1.0;
        [paths addObject:uiPath];
    }
    return paths;
}

- (NSString *)SVGRepresentation
{
    SVGMutableAttributeSet *attributes = [SVGMutableAttributeSet new];
    [attributes setAttributes:self.svgAttributes forPath:self.CGPath];
    return SVGStringFromCGPaths(@[(__bridge id)self.CGPath], attributes);
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SVGBezierPath * const copy = [super copyWithZone:zone];
    copy->_svgAttributes = [_svgAttributes copy];
    #if !TARGET_OS_IPHONE
    if(_CGPath)
        copy->_CGPath = CGPathRetain(_CGPath);
    #endif
    return copy;
}

- (SVGBezierPath *)pathBySettingSVGAttributes:(NSDictionary *)attributes
{
    NSParameterAssert(attributes);
    
    SVGBezierPath *path = [self copy];
    if (path) {
        if (path->_svgAttributes.count > 0) {
            path->_svgAttributes = [path->_svgAttributes mutableCopy];
            if (attributes) {
                [(NSMutableDictionary *)path->_svgAttributes setValuesForKeysWithDictionary:attributes];
            }
        } else {
            path->_svgAttributes = [attributes copy];
        }
    }
    return path;
}

#if TARGET_OS_IPHONE
+ (instancetype)bezierPathWithCGPath:(CGPathRef)cgPath
{
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 9) {
        return [super bezierPathWithCGPath:cgPath];
    } else {
        // iOS 8 and lower don't return instancetype...
        SVGBezierPath *path = [self new];
        path.CGPath = cgPath;
        return path;
    }
}
#else
+ (instancetype)bezierPathWithCGPath:(CGPathRef)cgPath
{
    SVGBezierPath *path = [self new];
    if (cgPath) {
        [path _svg_setCGPath:cgPath];
        CGPathApply(cgPath, (__bridge void *)path,
                    [](void * const info, const CGPathElement * const el)
        {
            SVGBezierPath * const path_ = (__bridge id)info;
            switch(el->type) {
                case kCGPathElementMoveToPoint:
                    [path_ moveToPoint:*(NSPoint *)el->points];
                    break;
                case kCGPathElementAddLineToPoint:
                    [path_ lineToPoint:*(NSPoint *)el->points];
                    break;
                case kCGPathElementAddQuadCurveToPoint:
                    [path_ curveToPoint:*(NSPoint *)(el->points+1)
                          controlPoint1:*(NSPoint *)(el->points)
                          controlPoint2:*(NSPoint *)(el->points)];
                    break;
                case kCGPathElementAddCurveToPoint:
                    [path_ curveToPoint:*(NSPoint *)(el->points+2)
                          controlPoint1:*(NSPoint *)(el->points)
                          controlPoint2:*(NSPoint *)(el->points+1)];
                    break;
                case kCGPathElementCloseSubpath:
                    [path_ closePath];
                    break;
            }
        });
    }
    return path;
}
- (void)dealloc
{
    [self _svg_setCGPath:NULL];
}

- (void)_svg_setCGPath:(CGPathRef)CGPath
{
    if (_CGPath)
        CGPathRelease(_CGPath);
    _CGPath = CGPath ? CGPathRetain(CGPath) : NULL;
}
- (CGPathRef)CGPath
{
    if (!_CGPath) {
        CGMutablePathRef path = CGPathCreateMutable();
        for (NSInteger i = 0; i < self.elementCount; ++i) {
            NSPoint pt[3];
            switch ([self elementAtIndex:i associatedPoints:pt]) {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, pt[0].x, pt[0].y);
                    break;
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, pt[0].x, pt[0].y);
                    break;
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, pt[0].x, pt[0].y, pt[1].x, pt[1].y, pt[2].x, pt[2].y);
                    break;
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
            }
        }
        [self _svg_setCGPath:path];
        CGPathRelease(path);
        _cgTransformBuffer = CGAffineTransformIdentity;
    } else if (!CGAffineTransformIsIdentity(_cgTransformBuffer)) {
        CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(_CGPath, &_cgTransformBuffer);
        [self _svg_setCGPath:transformedPath];
        CGPathRelease(transformedPath);
        _cgTransformBuffer = CGAffineTransformIdentity;
    }
    return _CGPath;
}
- (void)applyTransform:(CGAffineTransform)cgTransform
{
    NSAffineTransform *transform = [NSAffineTransform new];
    transform.transformStruct = (NSAffineTransformStruct) {
        .m11 = cgTransform.a,  .m12 = cgTransform.b,
        .m21 = cgTransform.c, .m22 = cgTransform.d,
        .tX = cgTransform.tx, .tY = cgTransform.ty,
    };
    _cgTransformBuffer = CGAffineTransformConcat(_cgTransformBuffer, cgTransform);
    [self transformUsingAffineTransform:transform];
}
#endif

- (CGRect) viewBox {
    NSString *viewBoxString = _svgAttributes[@"viewBox"];
    NSArray *stringArray = [viewBoxString componentsSeparatedByString:@" "];
    if (stringArray && stringArray.count == 4) {
        return CGRectMake(CGFloat([stringArray[0] doubleValue]), CGFloat([stringArray[1] doubleValue]), CGFloat([stringArray[2] doubleValue]), CGFloat([stringArray[3] doubleValue]));
    } else {
        return CGRectNull;
    }
}
@end


extern "C" CGRect SVGBoundingRectForPaths(NSArray<SVGBezierPath*> * const paths)
{
    CGRect bounds = CGRectZero;
    for(SVGBezierPath *path in paths) {
        bounds = CGRectUnion(bounds, path.bounds);
    }
    return bounds;
}

extern "C" void SVGDrawPaths(NSArray<SVGBezierPath*> * const paths,
                             CGContextRef const ctx,
                             CGRect const rect,
                             CGColorRef const defaultFillColor,
                             CGColorRef const defaultStrokeColor)
{
    SVGDrawPathsWithBlock(paths, ctx, rect, ^(SVGBezierPath *path) {
        CGColorRef fillColor = (__bridge CGColorRef)path.svgAttributes[@"fill"]
                            ?: defaultFillColor;
        if (fillColor && CGColorGetAlpha(fillColor) > 0) {
            [[PSVGColor colorWithCGColor:fillColor] setFill];
            [path fill];
        }
        CGColorRef strokeColor = (__bridge CGColorRef)path.svgAttributes[@"stroke"]
                              ?: defaultStrokeColor;
        if (strokeColor && CGColorGetAlpha(strokeColor) > 0) {
            [[PSVGColor colorWithCGColor:strokeColor] setStroke];
            [path stroke];
        }
    });
}
extern "C" void SVGDrawPathsWithBlock(NSArray<SVGBezierPath*> * const paths,
                                      CGContextRef const ctx,
                                      CGRect rect,
                                      void (^drawingBlock)(SVGBezierPath *path))
{
    if (!drawingBlock) {
        return;
    }
    
    CGRect const bounds  = SVGBoundingRectForPaths(paths);
    if (CGRectIsNull(rect)) {
        rect = bounds;
    }
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
    CGContextScaleCTM(ctx, rect.size.width  / bounds.size.width, rect.size.height / bounds.size.height);
#if TARGET_OS_IPHONE
    UIGraphicsPushContext(ctx);
#else
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO]];
#endif
    for (SVGBezierPath *path in paths) {
        CGContextSaveGState(ctx);
            drawingBlock(path);
        CGContextRestoreGState(ctx);
    }
#if TARGET_OS_IPHONE
    UIGraphicsPopContext();
#else
    [NSGraphicsContext restoreGraphicsState];
#endif
    CGContextRestoreGState(ctx);
}

#ifdef __LP64__
#define _CGFloor floor
#define _CGRound round
#else
#define _CGFloor floorf
#define _CGRound roundf
#endif

extern "C" CGRect SVGAdjustCGRectForContentsGravity(CGRect const aRect, CGSize const aSize, NSString * const aGravity)
{
    if(aSize.width != aRect.size.width || aSize.height != aRect.size.height) {
        if([aGravity isEqualToString:kCAGravityLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTop])
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottom])
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityCenter])
            return (CGRect) { aRect.origin.x + _CGRound(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + _CGRound(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottomLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + _CGFloor(aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottomRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y + (aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTopLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTopRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityResizeAspectFill]) {
            CGSize        size      = aSize;
            CGFloat const sizeRatio = size.width / size.height;
            CGFloat const rectRatio = aRect.size.width / aRect.size.height;
            if(sizeRatio > rectRatio) {
                size.width = _CGFloor(sizeRatio * aRect.size.height);
                size.height = aRect.size.height;
            } else {
                size.height = _CGFloor(aRect.size.width / sizeRatio);
                size.width = aRect.size.width;
            }
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - size.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - size.height/2),
                              size.width, size.height };
        } else if([aGravity isEqualToString:kCAGravityResizeAspect]) {
            CGSize size = aSize;
            if((size.height/size.width) < (aRect.size.height/aRect.size.width)) {
                size.height = _CGFloor((size.height/size.width) * aRect.size.width);
                size.width  = aRect.size.width;
            } else {
                size.width = _CGFloor((size.width/size.height) * aRect.size.height);
                size.height = aRect.size.height;
            }
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - size.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - size.height/2),
                              size.width, size.height };
        }
    }
    return aRect;
}

