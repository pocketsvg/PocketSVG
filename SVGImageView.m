#import "SVGImageView.h"
#import "SVGPathSerializer.h"

static CGRect _AdjustCGRectForContentMode(CGRect aRect, CGSize aSize, UIViewContentMode aMode);

@implementation SVGImageView {
    NSMutableArray *_untouchedPaths;
    NSMapTable *_pathAttributes;
    NSMutableArray *_shapeLayers;

#ifdef DEBUG
    dispatch_source_t _fileWatcher;
#endif
}

- (void)_init
{
    _shapeLayers = [NSMutableArray new];
    self.layer.shouldRasterize    = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

- (instancetype)initWithCoder:(NSCoder * const)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
        [self _init];
    return self;
}

- (instancetype)initWithFrame:(CGRect const)aFrame
{
    if((self = [super initWithFrame:aFrame]))
        [self _init];
    return self;
}

- (instancetype)init
{
    if((self = [super init]))
        [self _init];
    return self;
}

- (instancetype)initWithSVGNamed:(NSString * const)aName
                       fillColor:(UIColor * const)aFillColor
                     strokeColor:(UIColor * const)aStrokeColor
{
    if((self = [self init])) {
        self.fillColor   = aFillColor;
        self.strokeColor = aStrokeColor;
        self.svgFileName = aName;
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithSVGString:(NSString * const)aSVG
                        fillColor:(UIColor * const)aFillColor
                      strokeColor:(UIColor * const)aStrokeColor
{
    if((self = [self init])) {
        self.fillColor   = aFillColor;
        self.strokeColor = aStrokeColor;
        self.svgString   = aSVG;
        [self sizeToFit];
    }
    return self;
}

- (void)setSvgString:(NSString * const)aSVG
{
    [self willChangeValueForKey:@"svgString"];
    _svgString = aSVG;
    
    [_shapeLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_shapeLayers removeAllObjects];
    if([aSVG length] == 0)
        return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _untouchedPaths = [NSMutableArray new];
    NSMapTable *attributes;
    for(__strong id path in CGPathsFromSVGString(aSVG, &attributes)) {
        CAShapeLayer * const layer = [CAShapeLayer new];
        NSDictionary * const attrs = [attributes objectForKey:path];

        if(attrs[@"transform"]) {
            CGAffineTransform const transform = [attrs[@"transform"] CGAffineTransformValue];
            CGPathRef const newPath = CGPathCreateCopyByTransformingPath((__bridge CGPathRef)path, &transform);
            [attributes setObject:[attributes objectForKey:path]
                           forKey:(__bridge id)newPath];
            [attributes removeObjectForKey:path];
            path = (__bridge id)newPath;
        }

        layer.path = (__bridge CGPathRef)path;
        layer.lineWidth = attrs[@"stroke-width"] ? [attrs[@"stroke-width"] floatValue] : 1.0;
        layer.opacity   = attrs[@"opacity"] ? [attrs[@"opacity"] floatValue] : 1;
        [self.layer insertSublayer:layer atIndex:(unsigned int)[_shapeLayers count]];
        [_shapeLayers addObject:layer];
        [_untouchedPaths addObject:path];
    }
    _pathAttributes = attributes;

    [self setNeedsLayout];
    [self layoutIfNeeded];
    [CATransaction commit];
    [self didChangeValueForKey:@"svgString"];
}

- (void)setSvgFileName:(NSString *)aFileName
{
    [self willChangeValueForKey:@"svgFileName"];
    _svgFileName = aFileName;
    NSString * const path = [[NSBundle mainBundle] pathForResource:aFileName ofType:@"svg"];
    NSParameterAssert(aFileName && path);
    
    self.svgString = [NSString stringWithContentsOfFile:path
                                           usedEncoding:NULL
                                                  error:nil];
    [self didChangeValueForKey:@"svgFileName"];
#ifdef DEBUG
    __weak SVGImageView *self_ = self;
    int const fdes = open([path fileSystemRepresentation], O_RDONLY);
    _fileWatcher = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fdes,
                                          DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE,
                                          dispatch_get_main_queue());
    dispatch_source_set_event_handler(_fileWatcher, ^{
        unsigned long const l = dispatch_source_get_data(_fileWatcher);
        if(l & DISPATCH_VNODE_DELETE || l & DISPATCH_VNODE_WRITE) {
            NSLog(@"Reloading %@", aFileName);
            dispatch_source_cancel(_fileWatcher);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                self_.svgFileName = aFileName;
            });
        }
    });
    dispatch_source_set_cancel_handler(_fileWatcher, ^{
        close(fdes);
    });
    dispatch_resume(_fileWatcher);
#endif
}

- (void)dealloc
{
#ifdef DEBUG
    if(_fileWatcher)
        dispatch_source_cancel(_fileWatcher);
#endif
}

- (void)setFillColor:(UIColor *)aColor
{
    _fillColor = [aColor copy];
    [_shapeLayers setValue:(__bridge id)_fillColor.CGColor forKey:@"fillColor"];
}

- (void)setStrokeColor:(UIColor *)aColor
{
    _strokeColor = [aColor copy];
    [_shapeLayers setValue:(__bridge id)_strokeColor.CGColor forKey:@"strokeColor"];
}

- (CGSize)_pathSize
{
    CGRect bounds = CGRectZero;
    for(id path in _untouchedPaths) {
        bounds = CGRectUnion(bounds, CGPathGetPathBoundingBox((__bridge CGPathRef)path));
    }
    return bounds.size;
}

- (CGRect)_pathFrame
{
    return _AdjustCGRectForContentMode(self.bounds, [self _pathSize], self.contentMode);
}

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return [self _pathSize];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize const size  = [self _pathSize];
    CGRect const frame = [self _pathFrame];

    CGAffineTransform const scale = CGAffineTransformMakeScale(frame.size.width  / size.width,
                                                               frame.size.height / size.height);
    CGAffineTransform const layerTransform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(frame.origin.x,
                                                                                                      frame.origin.y),
                                                                     scale);
    
    NSAssert([_shapeLayers count] == [_untouchedPaths count],
             @"Layer & Path count in SVG Image View does not match!");
    for(NSUInteger i = 0; i < [_untouchedPaths count]; ++i) {
        CGPathRef      const path  = (__bridge CGPathRef)_untouchedPaths[i];
        CAShapeLayer * const layer = _shapeLayers[i];
        
        NSDictionary * const attrs = [_pathAttributes objectForKey:(__bridge id)path];
        layer.fillColor   = _fillColor.CGColor
                         ?: (__bridge CGColorRef)attrs[@"fill"]
                         ?: [[UIColor blackColor] CGColor];
        layer.strokeColor = _strokeColor.CGColor
                         ?: (__bridge CGColorRef)attrs[@"stroke"];
        
        CGRect const pathBounds = CGPathGetPathBoundingBox(path);
        layer.frame = CGRectApplyAffineTransform(pathBounds, layerTransform);
        CGAffineTransform const pathTransform = CGAffineTransformConcat(
                                                    CGAffineTransformMakeTranslation(-pathBounds.origin.x,
                                                                                     -pathBounds.origin.y),
                                                    scale);
        CGPathRef const transformedPath = CGPathCreateCopyByTransformingPath(path, &pathTransform);
        layer.path = transformedPath;
        CGPathRelease(transformedPath);
    }
}

@end

CGRect _AdjustCGRectForContentMode(CGRect const aRect, CGSize const aSize, UIViewContentMode const aMode)
{
    if(aSize.width != aRect.size.width || aSize.height != aRect.size.height) {
        switch(aMode) {
            case UIViewContentModeLeft:
                return (CGRect) { aRect.origin.x,
                                  aRect.origin.y + floor(aRect.size.height/2 - aSize.height/2),
                                  aSize.width, aSize.height };
            case UIViewContentModeRight:
                return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                                  aRect.origin.y + floor(aRect.size.height/2 - aSize.height/2),
                                  aSize.width, aSize.height };
            case UIViewContentModeTop:
                return (CGRect) { aRect.origin.x + floor(aRect.size.width/2 - aSize.width/2),
                                  aRect.origin.y,
                                  aSize.width, aSize.height };
            case UIViewContentModeBottom:
                return (CGRect) { aRect.origin.x + floor(aRect.size.width/2 - aSize.width/2),
                                  aRect.origin.y + floor(aRect.size.height - aSize.height),
                                  aSize.width, aSize.height };
            case UIViewContentModeCenter:
                return (CGRect) { aRect.origin.x + round(aRect.size.width/2 - aSize.width/2),
                                  aRect.origin.y + round(aRect.size.height/2 - aSize.height/2),
                                  aSize.width, aSize.height };
            case UIViewContentModeBottomLeft:
                return (CGRect) { aRect.origin.x,
                                  aRect.origin.y + floor(aRect.size.height - aSize.height),
                                  aSize.width, aSize.height };
            case UIViewContentModeBottomRight:
                return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                                  aRect.origin.y + (aRect.size.height - aSize.height),
                                  aSize.width, aSize.height };
            case UIViewContentModeTopLeft:
                return (CGRect) { aRect.origin.x,
                                  aRect.origin.y,
                                  aSize.width, aSize.height };
            case UIViewContentModeTopRight:
                return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                                  aRect.origin.y,
                                  aSize.width, aSize.height };
            case UIViewContentModeScaleAspectFill: {
                CGSize        size      = aSize;
                CGFloat const sizeRatio = size.width / size.height;
                CGFloat const rectRatio = aRect.size.width / aRect.size.height;
                if(sizeRatio > rectRatio) {
                    size.width = floorf(sizeRatio * aRect.size.height);
                    size.height = aRect.size.height;
                } else {
                    size.height = floorf(aRect.size.width / sizeRatio);
                    size.width = aRect.size.width;
                }
                return (CGRect) { aRect.origin.x + floorf(aRect.size.width/2 - size.width/2),
                                  aRect.origin.y + floorf(aRect.size.height/2 - size.height/2),
                                  size.width, size.height };
            } case UIViewContentModeScaleAspectFit: {
                CGSize size = aSize;
                if((size.height/size.width) < (aRect.size.height/aRect.size.width)) {
                    size.height = floorf((size.height/size.width) * aRect.size.width);
                    size.width  = aRect.size.width;
                } else {
                    size.width = floorf((size.width/size.height) * aRect.size.height);
                    size.height = aRect.size.height;
                }
                return (CGRect) { aRect.origin.x + floorf(aRect.size.width/2 - size.width/2),
                                  aRect.origin.y + floorf(aRect.size.height/2 - size.height/2),
                                  size.width, size.height };
            }
            default: break;
        }
    }
    return aRect;
}
