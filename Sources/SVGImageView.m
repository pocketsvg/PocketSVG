/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SVGImageView.h"
#import "SVGLayer.h"
#import "SVGPortability.h"
#import "SVGBezierPath.h"

@interface SVGImageView ()
// Allows for setting the SVG via IB
@property(nonatomic, copy) IBInspectable NSString *svgName;
@end

@implementation SVGImageView {
    SVGLayer *_svgLayer;
    
#ifdef DEBUG
    dispatch_source_t _fileWatcher;
#endif
}

#if TARGET_OS_IPHONE
- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _svgLayer = (SVGLayer *)self.layer;
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _svgLayer = (SVGLayer *)self.layer;
    }
    return self;
}
#else
- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _svgLayer = [SVGLayer new];
        self.wantsLayer = YES;
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _svgLayer = [SVGLayer new];
        self.wantsLayer = YES;
    }
    return self;
}
#endif

- (instancetype)initWithContentsOfURL:(NSURL *)url {
    if (self = [self init]) {
        [self _cr_loadSVGFromURL:url];
    }
    return self;
}


#if TARGET_OS_IPHONE
+ (Class)layerClass
{
    return [SVGLayer class];
}
#else
- (CALayer *)makeBackingLayer
{
    return _svgLayer;
}
- (BOOL)isFlipped
{
    return YES;
}
- (void)sizeToFit
{
    self.bounds = (NSRect) { self.bounds.origin, [self sizeThatFits:CGSizeZero] };
}
#endif


- (NSArray<SVGBezierPath*> *)paths { return _svgLayer.paths; }
- (void)setPaths:(NSArray<SVGBezierPath *> *)paths
{
#if defined(DEBUG) && !defined(POCKETSVG_DISABLE_FILEWATCH)
    if(_fileWatcher)
    (void)((dispatch_source_cancel(_fileWatcher))), _fileWatcher = NULL;
#endif
    _svgLayer.paths = paths;
}
- (void)setSvgName:(NSString *)svgName
{
#if !TARGET_INTERFACE_BUILDER
    NSBundle * const bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:svgName withExtension:@"svg"];
    NSParameterAssert(!svgName || url);
#else
    NSString *path = nil;
    NSPredicate * const pred = [NSPredicate predicateWithFormat:@"lastPathComponent LIKE[c] %@",
                                [svgName stringByAppendingPathExtension:@"svg"]];
    NSString * const sourceDirs = [[NSProcessInfo processInfo] environment][@"IB_PROJECT_SOURCE_DIRECTORIES"];
    for(__strong NSString *dir in [sourceDirs componentsSeparatedByString:@":"]) {
        // Go up the hierarchy until we don't find an xcodeproj
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
    NSURL *url = path ? [NSURL fileURLWithPath:path] : nil;
#endif

    [self _cr_loadSVGFromURL:url];
}

- (void)_cr_loadSVGFromURL:(NSURL *)url
{
#if defined(DEBUG) && !defined(POCKETSVG_DISABLE_FILEWATCH)
    if(_fileWatcher)
        dispatch_source_cancel(_fileWatcher);
    
    int const fdes = open([url fileSystemRepresentation], O_RDONLY);
    _fileWatcher = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fdes,
                                          DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE,
                                          dispatch_get_main_queue());
    dispatch_source_set_event_handler(_fileWatcher, ^{
        unsigned long const l = dispatch_source_get_data(self->_fileWatcher);
        if(l & DISPATCH_VNODE_DELETE || l & DISPATCH_VNODE_WRITE) {
            NSLog(@"Reloading %@", url.lastPathComponent);
            dispatch_source_cancel(self->_fileWatcher);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [SVGBezierPath resetCache];
                [self _cr_loadSVGFromURL:url];
            });
        }
    });
    dispatch_source_set_cancel_handler(_fileWatcher, ^{
        close(fdes);
    });
    dispatch_resume(_fileWatcher);
#endif
    
    _svgLayer.paths = [SVGBezierPath pathsFromSVGAtURL:url];
}

- (void)dealloc
{
#ifdef DEBUG
    if(_fileWatcher)
        dispatch_source_cancel(_fileWatcher);
#endif
}


- (PSVGColor *)fillColor { return _svgLayer.fillColor
                                  ? [PSVGColor colorWithCGColor:_svgLayer.fillColor]
                                  : nil; }
- (void)setFillColor:(PSVGColor * const)aColor { _svgLayer.fillColor = aColor.CGColor; }

- (PSVGColor *)strokeColor { return _svgLayer.strokeColor
                                    ? [PSVGColor colorWithCGColor:_svgLayer.strokeColor]
                                    : nil; }
- (void)setStrokeColor:(PSVGColor * const)aColor { _svgLayer.strokeColor = aColor.CGColor; }

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.layer.preferredFrameSize;
}
- (CGSize)intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}

- (CGRect) viewBox {
    return _svgLayer.viewBox;
}
@end
