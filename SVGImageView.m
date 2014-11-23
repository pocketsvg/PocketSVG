#import "SVGImageView.h"
#import "SVGLayer.h"

@implementation SVGImageView
@dynamic fillColor, strokeColor, svgFileName, svgString;

#if TARGET_OS_IPHONE
+ (Class)layerClass
{
    return [SVGLayer class];
}
#else
- (CALayer *)makeBackingLayer
{
    return [SVGLayer new];
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

- (id)forwardingTargetForSelector:(SEL const)aSelector
{
    if([self.layer respondsToSelector:aSelector])
        return self.layer;
    else
        return nil;
}

- (void)setValue:(id const)aValue forUndefinedKey:(NSString * const)aKey
{
    if(self.layer)
        [self.layer setValue:aValue forKey:aKey];
    else
        [super setValue:aValue forUndefinedKey:aKey];
}

- (CGSize)sizeThatFits:(CGSize)aSize
{
    return self.layer.preferredFrameSize;
}

@end
