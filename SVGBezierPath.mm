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

+ (NSArray *)pathsFromSVGString:(NSString * const)svgString
{
    SVGAttributeSet *cgAttrs;
    NSArray        * const pathRefs = CGPathsFromSVGString(svgString, &cgAttrs);
    NSMutableArray * const paths    = [NSMutableArray arrayWithCapacity:pathRefs.count];
    for(id pathRef in pathRefs) {
        SVGBezierPath * const uiPath = [self bezierPathWithCGPath:(__bridge CGPathRef)pathRef];
        uiPath->_svgAttributes = [cgAttrs attributesForPath:(__bridge CGPathRef)pathRef] ?: @{};
        [paths addObject:uiPath];
    }
    return paths;
}

- (NSString *)SVGRepresentation
{
    return SVGStringFromCGPaths(@[(__bridge id)self.CGPath], nil);
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
@end
