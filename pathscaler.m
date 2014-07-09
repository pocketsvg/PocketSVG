#import "PocketSVG.h"

int main(int argc, char *argv[])
{
    NSCAssert(argc == 3, @"USAGE: pathscaler <scale> <svgPath>");
    float const scale        = [[NSString stringWithUTF8String:argv[1]] floatValue];
    NSString * const svgPath = [NSString stringWithUTF8String:argv[2]];

    NSString * const svg = [NSString stringWithContentsOfFile:svgPath usedEncoding:NULL error:NULL];
    NSCAssert(svg, @"Failed to open SVG!");
    NSMapTable *attributes;
    NSArray * const inPaths = PSVGPathsFromSVGString(svg, &attributes);

    NSMutableArray * const outPaths = [NSMutableArray arrayWithCapacity:[inPaths count]];
    NSMapTable * const outAttributes = [NSMapTable strongToStrongObjectsMapTable];
    CGAffineTransform const transform = CGAffineTransformMakeScale(scale, scale);
    for(id path in inPaths) {
        CGPathRef scaledPath = CGPathCreateCopyByTransformingPath((__bridge CGPathRef)path, &transform);
        [outPaths addObject:(__bridge id)scaledPath];
        [outAttributes setObject:[attributes objectForKey:path] forKey:(__bridge id)scaledPath];
    }
    printf("%s\n", [PSVGFromPaths(outPaths, outAttributes) UTF8String]);
    return 0;
}
