#import "SVGLayer.h"
#import "SVGPortability.h"
#import "SVGPathSerializing.h"

CGRect _AdjustCGRectForContentsGravity(CGRect aRect, CGSize aSize, NSString *aGravity);

@implementation SVGLayer {
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
#if TARGET_OS_IPHONE
    self.shouldRasterize = YES;
    self.rasterizationScale = [[UIScreen mainScreen] scale];
#endif
}

- (instancetype)initWithCoder:(NSCoder * const)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
        [self _init];
    return self;
}

- (instancetype)init
{
    if((self = [super init]))
        [self _init];
    return self;
}

- (void)setSvgSource:(NSString * const)aSVG
{
    [self willChangeValueForKey:@"svgSource"];
#ifdef DEBUG
    if(_fileWatcher)
        dispatch_source_cancel(_fileWatcher), _fileWatcher = NULL;
#endif

    _svgSource = aSVG;
    
    [_shapeLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_shapeLayers removeAllObjects];
    _untouchedPaths = [NSMutableArray new];
    if([aSVG length] == 0)
        return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    NSMapTable *attributes;
    for(__strong id path in CGPathsFromSVGString(aSVG, &attributes)) {
        CAShapeLayer * const layer = [CAShapeLayer new];
        NSDictionary * const attrs = [attributes objectForKey:path];

        if(attrs[@"transform"]) {
            CGAffineTransform const transform = [attrs[@"transform"] svg_CGAffineTransformValue];
            CGPathRef const newPath = CGPathCreateCopyByTransformingPath((__bridge CGPathRef)path, &transform);
            [attributes setObject:[attributes objectForKey:path]
                           forKey:(__bridge id)newPath];
            [attributes removeObjectForKey:path];
            path = (__bridge id)newPath;
            CGPathRelease(newPath);
        }

        layer.path = (__bridge CGPathRef)path;
        layer.lineWidth = attrs[@"stroke-width"] ? [attrs[@"stroke-width"] floatValue] : 1.0;
        layer.opacity   = attrs[@"opacity"] ? [attrs[@"opacity"] floatValue] : 1;
        [self insertSublayer:layer atIndex:(unsigned int)[_shapeLayers count]];
        [_shapeLayers addObject:layer];
        [_untouchedPaths addObject:path];
    }
    _pathAttributes = attributes;

    [self setNeedsLayout];
    [CATransaction commit];
    [self didChangeValueForKey:@"svgSource"];
}

- (void)loadSVGNamed:(NSString * const)aFileName
{
#if !TARGET_INTERFACE_BUILDER
    NSString * const path = [[NSBundle mainBundle] pathForResource:aFileName ofType:@"svg"];
    NSParameterAssert(!aFileName || path);
#else
    NSString *path = nil;
    NSPredicate * const pred = [NSPredicate predicateWithFormat:@"lastPathComponent LIKE[c] %@",
                                [aFileName stringByAppendingPathExtension:@"svg"]];
    NSString * const sourceDirs = [[NSProcessInfo processInfo] environment][@"IB_PROJECT_SOURCE_DIRECTORIES"];
    for(__strong NSString *dir in [sourceDirs componentsSeparatedByString:@":"]) {
        // Go up the hiearchy until we don't find an xcodeproj
        NSString *projectDir = dir;
        NSPredicate *xcodePredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH[c] %@", @".xcodeproj"];
        do {
            NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
            if([[contents filteredArrayUsingPredicate:xcodePredicate] count] > 0) {
                projectDir = dir;
            }
            NSLog(@"%@", dir);
        } while(![(dir = dir.stringByDeletingLastPathComponent) isEqual:@"/"]);

        NSArray * const results = [[[NSFileManager defaultManager] subpathsAtPath:projectDir]
                                   filteredArrayUsingPredicate:pred];
        if([results count] > 0) {
            path = [projectDir stringByAppendingPathComponent:results[0]];
            break;
        }
    }
#endif
    
    self.svgSource = [NSString stringWithContentsOfFile:path
                                           usedEncoding:NULL
                                                  error:nil];

#ifdef DEBUG
    __weak SVGLayer *self_ = self;
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
                [self_ loadSVGNamed:aFileName];
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

- (void)setFillColor:(CGColorRef)aColor
{
    _fillColor = aColor;
    [_shapeLayers setValue:(__bridge id)_fillColor forKey:@"fillColor"];
}

- (void)setStrokeColor:(CGColorRef)aColor
{
    _strokeColor = aColor;
    [_shapeLayers setValue:(__bridge id)_strokeColor forKey:@"strokeColor"];
}

- (CGSize)preferredFrameSize
{
    CGRect bounds = CGRectZero;
    for(id path in _untouchedPaths) {
        bounds = CGRectUnion(bounds, CGPathGetPathBoundingBox((__bridge CGPathRef)path));
    }
    return bounds.size;
}

- (void)layoutSublayers
{
    [super layoutSublayers];

#if !TARGET_OS_IPHONE && TARGET_INTERFACE_BUILDER
    self.sublayerTransform = CATransform3DTranslate(CATransform3DMakeScale(1, -1, 1),
                                                    0, -self.bounds.size.height, 0);
#endif

    CGSize const size  = [self preferredFrameSize];
    CGRect const frame = _AdjustCGRectForContentsGravity(self.bounds, size, self.contentsGravity);

    CGAffineTransform const scale = CGAffineTransformMakeScale(frame.size.width  / size.width,
                                                               frame.size.height / size.height);
    CGAffineTransform const layerTransform = CGAffineTransformConcat(scale,
                                                                     CGAffineTransformMakeTranslation(frame.origin.x,
                                                                                                      frame.origin.y));

    NSAssert([_shapeLayers count] == [_untouchedPaths count],
             @"Layer & Path count in SVG Image View does not match!");

    for(NSUInteger i = 0; i < [_untouchedPaths count]; ++i) {
        CGPathRef      const path  = (__bridge CGPathRef)_untouchedPaths[i];
        CAShapeLayer * const layer = _shapeLayers[i];
        
        NSDictionary * const attrs = [_pathAttributes objectForKey:(__bridge id)path];
        layer.fillColor   = _fillColor
                         ?: (__bridge CGColorRef)attrs[@"fill"]
                         ?: [[SVGUI(Color) blackColor] CGColor];
        layer.strokeColor = _strokeColor
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

CGRect _AdjustCGRectForContentsGravity(CGRect const aRect, CGSize const aSize, NSString const *aGravity)
{
    if(aSize.width != aRect.size.width || aSize.height != aRect.size.height) {
        if([aGravity isEqualToString:kCAGravityLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + floor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y + floor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTop])
            return (CGRect) { aRect.origin.x + floor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottom])
            return (CGRect) { aRect.origin.x + floor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + floor(aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityCenter])
            return (CGRect) { aRect.origin.x + round(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + round(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottomLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + floor(aRect.size.height - aSize.height),
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
                size.width = floorf(sizeRatio * aRect.size.height);
                size.height = aRect.size.height;
            } else {
                size.height = floorf(aRect.size.width / sizeRatio);
                size.width = aRect.size.width;
            }
            return (CGRect) { aRect.origin.x + floorf(aRect.size.width/2 - size.width/2),
                              aRect.origin.y + floorf(aRect.size.height/2 - size.height/2),
                              size.width, size.height };
        } else if([aGravity isEqualToString:kCAGravityResizeAspect]) {
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
    }
    return aRect;
}
