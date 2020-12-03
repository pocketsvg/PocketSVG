/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGLayer.h"
#import "SVGPortability.h"
#import "PocketSVG.h"
#import "SVGBezierPath.h"
#import "SVGEngine.h"

@implementation SVGLayer {
    NSMutableArray<SVGBezierPath*> *_untouchedPaths;
    NSMutableArray *_shapeLayers;
}

- (void)commonInit
{
    _shapeLayers = [NSMutableArray new];
#if TARGET_OS_IPHONE
    self.shouldRasterize = YES;
    self.rasterizationScale = UIScreen.mainScreen.scale;
#endif
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url
{
    if ((self = [self init])) {
        [self setPaths:[SVGBezierPath pathsFromSVGAtURL:url]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder * const)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    CGColorRelease(_fillColor);
    CGColorRelease(_strokeColor);
}

- (CGRect) viewBox {
    return [[_paths firstObject] viewBox];
}

- (void)setPaths:(NSArray<SVGBezierPath*> *)paths
{
    [self willChangeValueForKey:@"paths"];
    _paths = paths;
    [_shapeLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_shapeLayers removeAllObjects];
    _untouchedPaths = [NSMutableArray new];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for(__strong SVGBezierPath *path in paths) {
        if ([path.svgAttributes[@"display"] isEqualToString:@"none"]) {
            continue;
        }        
        CAShapeLayer * const layer = [CAShapeLayer new];
        #if TARGET_OS_IPHONE
            layer.contentsScale = UIScreen.mainScreen.scale;
        #endif

        if(path.svgAttributes[@"transform"]) {
            SVGBezierPath * const newPath = [path copy];
            [newPath applyTransform:[path.svgAttributes[@"transform"] svg_CGAffineTransformValue]];
            path = newPath;
        }

        layer.path = path.CGPath;
        layer.lineWidth = path.lineWidth;
        layer.opacity   = path.svgAttributes[@"opacity"] ? [path.svgAttributes[@"opacity"] floatValue] : 1;
        [self insertSublayer:layer atIndex:(unsigned int)[_shapeLayers count]];
        [_shapeLayers addObject:layer];
        [_untouchedPaths addObject:path];
    }
    [self setNeedsLayout];
    [CATransaction commit];
    [self didChangeValueForKey:@"paths"];
}

- (void)setFillColor:(CGColorRef)aColor
{
    CGColorRetain(aColor);
    CGColorRelease(_fillColor);
    _fillColor = aColor;

    [_shapeLayers setValue:(__bridge id)_fillColor forKey:@"fillColor"];
}

- (void)setStrokeColor:(CGColorRef)aColor
{
    CGColorRetain(aColor);
    CGColorRelease(_strokeColor);
    _strokeColor = aColor;

    [_shapeLayers setValue:(__bridge id)_strokeColor forKey:@"strokeColor"];
}

- (CGSize)preferredFrameSize
{
    return SVGBoundingRectForPaths(_untouchedPaths).size;
}

- (void)layoutSublayers
{
    [super layoutSublayers];

#if !TARGET_OS_IPHONE && TARGET_INTERFACE_BUILDER
    self.sublayerTransform = CATransform3DTranslate(CATransform3DMakeScale(1, -1, 1),
                                                    0, -self.bounds.size.height, 0);
#endif

    CGSize const size  = [self preferredFrameSize];
    CGRect const frame = SVGAdjustCGRectForContentsGravity(self.bounds, size, self.contentsGravity);

    CGAffineTransform const scale = CGAffineTransformMakeScale(frame.size.width  / size.width,
                                                               frame.size.height / size.height);
    CGAffineTransform const layerTransform = CGAffineTransformConcat(scale,
                                                                     CGAffineTransformMakeTranslation(frame.origin.x,
                                                                                                      frame.origin.y));

    NSAssert([_shapeLayers count] == [_untouchedPaths count],
             @"Layer & Path count in SVG Image View does not match!");

    for(NSUInteger i = 0; i < [_untouchedPaths count]; ++i) {
        SVGBezierPath * const path  = _untouchedPaths[i];
        CAShapeLayer  * const layer = _shapeLayers[i];
        
        layer.fillColor   = _fillColor
                         ?: (__bridge CGColorRef)path.svgAttributes[@"fill"]
                         ?: [[PSVGColor blackColor] CGColor];
        layer.strokeColor = _strokeColor
                         ?: (__bridge CGColorRef)path.svgAttributes[@"stroke"];
        if (_scaleLineWidth) {
            CGFloat lineScale = (frame.size.width/size.width + frame.size.height/size.height) / 2.0;
            layer.lineWidth = path.lineWidth * lineScale;
        }
        layer.fillRule = [path.svgAttributes[@"fill-rule"] isEqualToString:@"evenodd"] ? kCAFillRuleEvenOdd : kCAFillRuleNonZero;
        NSString *lineCap = path.svgAttributes[@"stroke-linecap"];
        layer.lineCap = [lineCap isEqualToString:@"round"] ? kCALineCapRound : ([lineCap isEqualToString:@"square"] ? kCALineCapSquare : kCALineCapButt);
        NSString *lineJoin = path.svgAttributes[@"stroke-linejoin"];
        layer.lineJoin = [lineJoin isEqualToString:@"round"] ? kCALineJoinRound : ([lineJoin isEqualToString:@"bevel"] ? kCALineJoinBevel : kCALineJoinMiter);
        NSString *miterLimit = path.svgAttributes[@"stroke-miterlimit"];
        layer.miterLimit = miterLimit ? [miterLimit doubleValue] : layer.miterLimit;
        NSString *dasharray = path.svgAttributes[@"stroke-dasharray"];
        layer.lineDashPattern = dasharray ? [[dasharray componentsSeparatedByString:@","] valueForKey:@"floatValue"] : nil;
        
        CGRect const pathBounds = path.bounds;
        layer.frame = CGRectApplyAffineTransform(pathBounds, layerTransform);
        CGAffineTransform const pathTransform = CGAffineTransformConcat(
                                                    CGAffineTransformMakeTranslation(-pathBounds.origin.x,
                                                                                     -pathBounds.origin.y),
                                                    scale);
        CGPathRef const transformedPath = CGPathCreateCopyByTransformingPath(path.CGPath, &pathTransform);
        layer.path = transformedPath;
        CGPathRelease(transformedPath);
    }
}

@end
