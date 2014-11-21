//
//  SVGPathSerializer.m
//
//  Copyright (c) 2013 Ariel Elkin, Fjölnir Ásgeirsson, Ponderwell, and Contributors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "SVGPathSerializer.h"

NSString * const kValidSVGCommands = @"CcMmLlHhVvZzqQaAsS";

static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(uint32_t triplet) CF_RETURNS_RETAINED;
static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(NSString *tripletStr) CF_RETURNS_RETAINED;
static                               NSString  *CGColorToHexTriplet(CGColorRef color, CGFloat *outAlpha);

@interface _SVGParser : NSObject {
    CGMutablePathRef _path;
    CGPoint          _lastControlPoint;
    unichar          _lastCommand;
}

- (CGPathRef)parsePath:(NSString *)attr;
- (void)appendSVGMoveto:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGLineto:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGCurve:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGShorthandCurve:(unichar)cmd withOperands:(NSArray *)operands;
@end

NSArray *CGPathsFromSVGString(NSString * const svgString, NSMapTable **outAttributes)
{
    NSCParameterAssert(svgString);
    
    static NSRegularExpression *attrRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attrRegex = [NSRegularExpression
                     regularExpressionWithPattern:@"[^\\w]([\\w_-]+)\\s*=\\s*\"([^\"]+)\""
                     options:NSRegularExpressionCaseInsensitive
                     error:nil];
    });
   
    _SVGParser    * const parser = [_SVGParser new];
    NSMutableArray * const paths = [NSMutableArray new];
    if(outAttributes)
        *outAttributes = [NSMapTable strongToStrongObjectsMapTable];

    NSArray * const candidates = [svgString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    for(NSString *candidate in candidates) {
        if(![candidate hasPrefix:@"path"])
            continue;

        NSMutableDictionary * const attrs   = outAttributes ? [NSMutableDictionary new] : nil;
        NSArray             * const matches = [attrRegex matchesInString:candidate
                                                                 options:0
                                                                   range:(NSRange) { 0, [candidate length] }];
        
        CGPathRef path = NULL;
        for(NSTextCheckingResult *match in matches) {
            NSString * const attr    = [candidate substringWithRange:(NSRange)[match rangeAtIndex:1]],
                     * const content = [candidate substringWithRange:(NSRange)[match rangeAtIndex:2]];
            
            if([attr isEqualToString:@"d"])
                path = [parser parsePath:content];
            else if(!outAttributes)
                continue;
            else if([attr isEqualToString:@"fill"] || [attr isEqualToString:@"stroke"])
                if([content isEqualToString:@"none"]) {
                    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
                    attrs[attr] = (__bridge id)CGColorCreate(colorSpace, (CGFloat[]) { 1, 1, 1, 0 });
                    CFRelease(colorSpace);
                } else
                    attrs[attr] = (__bridge id)CGColorFromHexTriplet(content);
            else
                attrs[attr] = content;
        }

        if(!path) {
            NSLog(@"*** Error: Invalid/missing d attribute in %@", candidate);
            continue;
        } else {
            [paths addObject:(__bridge id)path];
            if(outAttributes) {
                if(attrs[@"fill"] && attrs[@"fill-opacity"] && [attrs[@"fill-opacity"] floatValue] < 1.0) {
                     attrs[@"fill"] = (__bridge id)CGColorCreateCopyWithAlpha((__bridge CGColorRef)attrs[@"fill"],
                                                                              [attrs[@"fill-opacity"] floatValue]);
                    [attrs removeObjectForKey:@"fill-opacity"];
                }
                if(attrs[@"stroke"] && attrs[@"stroke-opacity"] && [attrs[@"stroke-opacity"] floatValue] < 1.0) {
                    attrs[@"stroke"] = (__bridge id)CGColorCreateCopyWithAlpha((__bridge CGColorRef)attrs[@"stroke"],
                                                                               [attrs[@"stroke-opacity"] floatValue]);
                    [attrs removeObjectForKey:@"stroke-opacity"];
                }
                if([attrs count] > 0)
                    [*outAttributes setObject:attrs forKey:(__bridge id)path];
            }
        }
    }
    return paths;
}

static void _pathWalker(void * const info, const CGPathElement * const el);

NSString *SVGStringFromCGPaths(NSArray * const paths, NSMapTable * const attributes)
{
    CGRect bounds = CGRectZero;
    NSMutableString * const svg = [NSMutableString new];
    for(id path in paths) {
        bounds = CGRectUnion(bounds, CGPathGetBoundingBox((__bridge CGPathRef)path));
        
        [svg appendString:@"  <path"];
        NSDictionary *pathAttrs = [attributes objectForKey:path];
        for(NSString *key in pathAttrs) {
            if(![pathAttrs[key] isKindOfClass:[NSString class]]) { // Color
                CGFloat alpha;
                [svg appendFormat:@" %@=\"%@\"", key, CGColorToHexTriplet((__bridge CGColorRef)pathAttrs[key], &alpha)];
                if(alpha < 1.0)
                    [svg appendFormat:@" %@-opacity=\"%.2g\"", key, alpha];
            } else
                [svg appendFormat:@" %@=\"%@\"", key, pathAttrs[key]];
        }
        [svg appendString:@" d=\""];
        CGPathApply((__bridge CGPathRef)path, (__bridge void *)svg, &_pathWalker);
        [svg appendString:@"\"/>\n"];
    }
    
    return [NSString stringWithFormat:
            @"<svg xmlns=\"http://www.w3.org/2000/svg\""
            @" xmlns:xlink=\"http://www.w3.org/1999/xlink\""
            @" width=\"%.0f\" height=\"%.0f\">\n%@\n</svg>\n",
            bounds.size.width,
            bounds.size.height,
            svg];

}

static void _pathWalker(void * const info, const CGPathElement * const el)
{
    NSMutableString * const svg = (__bridge id)info;
    
    static NSNumberFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [NSNumberFormatter new];
        fmt.numberStyle = NSNumberFormatterDecimalStyle;
        fmt.maximumSignificantDigits = 3;
    });
    
    #define FMT(n) [fmt stringFromNumber:@(n)]
    switch(el->type) {
        case kCGPathElementMoveToPoint:
            [svg appendFormat:@"M%@,%@", FMT(el->points[0].x), FMT(el->points[0].y)];
            break;
        case kCGPathElementAddLineToPoint:
            [svg appendFormat:@"L%@,%@", FMT(el->points[0].x), FMT(el->points[0].y)];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            [svg appendFormat:@"Q%@,%@,%@,%@", FMT(el->points[0].x), FMT(el->points[0].y),
                                                   FMT(el->points[1].x), FMT(el->points[1].y)];
            break;
        case kCGPathElementAddCurveToPoint:
            [svg appendFormat:@"C%@,%@,%@,%@,%@,%@", FMT(el->points[0].x), FMT(el->points[0].y),
                                                           FMT(el->points[1].x), FMT(el->points[1].y),
                                                           FMT(el->points[2].x), FMT(el->points[2].y)];
            break;
        case kCGPathElementCloseSubpath:
            [svg appendFormat:@"Z"];
            break;
	}
    #undef FMT
}



@implementation _SVGParser

- (CGPathRef)parsePath:(NSString * const)attr
{
#ifdef SVG_PATH_SERIALIZER_DEBUG
    NSLog(@"d=%@", attr);
#endif
    _path = CGPathCreateMutable();
    CGPathMoveToPoint(_path, NULL, 0, 0);
    
    NSScanner *scanner = [NSScanner scannerWithString:attr];
    NSMutableCharacterSet *separators = [NSMutableCharacterSet characterSetWithCharactersInString:@","];
    [separators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    scanner.charactersToBeSkipped = separators;
    
    NSCharacterSet *commands = [NSCharacterSet characterSetWithCharactersInString:kValidSVGCommands];
    
    NSString *cmd;
    NSMutableArray *operands = [NSMutableArray new];
    while([scanner scanCharactersFromSet:commands intoString:&cmd]) {
        if([cmd length] > 1) {
            scanner.scanLocation -= [cmd length]-1;
        } else {
            float operand;
            while([scanner scanFloat:&operand]) {
                [operands addObject:@(operand)];
            }
        }
        [self handleCommand:[cmd characterAtIndex:0] withOperands:operands];
        [operands removeAllObjects];
    }
    if(scanner.scanLocation < [attr length])
        NSLog(@"*** SVG parse error at index: %d: '%c'",
              (int)scanner.scanLocation, [attr characterAtIndex:scanner.scanLocation]);
    
    return _path;
}

- (void)handleCommand:(unichar const)opcode withOperands:(NSArray * const)operands
{
#ifdef SVG_PATH_SERIALIZER_DEBUG
    NSLog(@"%c %@", opcode, operands);
#endif
    switch (opcode) {
        case 'M':
        case 'm':
            [self appendSVGMoveto:opcode withOperands:operands];
            break;
        case 'L':
        case 'l':
        case 'H':
        case 'h':
        case 'V':
        case 'v':
            [self appendSVGLineto:opcode withOperands:operands];
            break;
        case 'C':
        case 'c':
            [self appendSVGCurve:opcode withOperands:operands];
            break;
        case 'S':
        case 's':
            [self appendSVGShorthandCurve:opcode withOperands:operands];
            break;
        case 'a':
        case 'A':
            NSLog(@"*** Error: Elliptical arcs not supported"); // TODO
            break;
        case 'Z':
        case 'z':
            CGPathCloseSubpath(_path);
            break;
        default:
            NSLog(@"*** Error: Cannot process command : '%c'", opcode);
            break;
    }
    _lastCommand = opcode;
}

- (void)appendSVGMoveto:(unichar const)cmd withOperands:(NSArray * const)operands
{
    if ([operands count]%2 != 0) {
        NSLog(@"*** Error: Invalid parameter count in M style token");
        return;
    }
    
    for(NSUInteger i = 0; i < [operands count]; i += 2) {
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat x = [operands[i+0]   floatValue] + (cmd == 'm' ? currentPoint.x : 0);
        CGFloat y = [operands[i+1]   floatValue] + (cmd == 'm' ? currentPoint.y : 0);

        if(i == 0)
            CGPathMoveToPoint(_path, NULL, x, y);
        else
            CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

- (void)appendSVGLineto:(unichar const)cmd withOperands:(NSArray * const)operands
{
    for(NSUInteger i = 0; i < [operands count]; ++i) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        switch(cmd) {
            case 'l':
                x = currentPoint.x;
                y = currentPoint.y;
            case 'L':
                x += [operands[i] floatValue];
                if (++i == [operands count]) {
                    NSLog(@"*** Error: Invalid parameter count in L style token");
                    return;
                }
                y += [operands[i] floatValue];
                break;
            case 'h' :
                x = currentPoint.x;
            case 'H' :
                x += [operands[i] floatValue];
                y = currentPoint.y;
                break;
            case 'v' :
                y = currentPoint.y;
            case 'V' :
                y += [operands[i] floatValue];
                x = currentPoint.x;
                break;
            default:
                NSLog(@"*** Error: Unrecognised L style command.");
                return;
        }
        CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

- (void)appendSVGCurve:(unichar const)cmd withOperands:(NSArray * const)operands
{
    if([operands count]%6 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for C command");
        return;
    }
    
    // (x1, y1, x2, y2, x, y)
    for(NSUInteger i = 0; i < [operands count]; i += 6) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = [operands[i+0] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y1 = [operands[i+1] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        CGFloat const x2 = [operands[i+2] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y2 = [operands[i+3] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        CGFloat const x  = [operands[i+4] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y  = [operands[i+5] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        
        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

- (void)appendSVGShorthandCurve:(unichar const)cmd withOperands:(NSArray * const)operands
{
    if([operands count]%4 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for S command");
        return;
    }
    if(_lastCommand != 'C' && _lastCommand != 'c' && _lastCommand != 'S' && _lastCommand != 's')
        _lastControlPoint = CGPathGetCurrentPoint(_path);
    
    // (x2, y2, x, y)
    for(NSUInteger i = 0; i < [operands count]; i += 4) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = currentPoint.x + (currentPoint.x - _lastControlPoint.x);
        CGFloat const y1 = currentPoint.y + (currentPoint.y - _lastControlPoint.y);
        CGFloat const x2 = [operands[i+0] floatValue] + (cmd == 's' ? currentPoint.x : 0);
        CGFloat const y2 = [operands[i+1] floatValue] + (cmd == 's' ? currentPoint.y : 0);
        CGFloat const x  = [operands[i+2] floatValue] + (cmd == 's' ? currentPoint.x : 0);
        CGFloat const y  = [operands[i+3] floatValue] + (cmd == 's' ? currentPoint.y : 0);

        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

@end


#pragma mark -

#if TARGET_OS_IPHONE
@implementation UIBezierPath (SVGPathSerializer)

+ (NSArray *)pathsFromContentsOfSVGFile:(NSString * const)aPath
{
#ifndef NS_BLOCK_ASSERTIONS
    BOOL isDir;
    NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && !isDir);
#endif
    return [self pathsFromSVGString:[NSString stringWithContentsOfFile:aPath usedEncoding:NULL error:nil]];
}

+ (NSArray *)pathsFromSVGString:(NSString * const)svgString
{
    NSArray        * const pathRefs = CGPathsFromSVGString(svgString, NULL);
    NSMutableArray * const paths    = [NSMutableArray arrayWithCapacity:pathRefs.count];
    for(id pathRef in pathRefs) {
        [paths addObject:[UIBezierPath bezierPathWithCGPath:(__bridge CGPathRef)pathRef]];
    }
    return paths;
}

- (NSString *)SVGRepresentation
{
    return SVGStringFromCGPaths(@[(__bridge id)self.CGPath], nil);
}
@end
#endif

static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(uint32_t const triplet)
{
    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef const color = CGColorCreate(colorSpace,
                             (CGFloat[]) {
                                 ((float)((triplet & 0xFF0000) >> 16)) / 255.0,
                                 ((float)((triplet & 0xFF00) >> 8))    / 255.0,
                                 ((float)(triplet & 0xFF))             / 255.0,
                                 1
                             });
    CFRelease(colorSpace);
    return color;
}

static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(NSString *tripletStr)
{
    NSCParameterAssert([tripletStr hasPrefix:@"#"]);
    NSCParameterAssert([tripletStr length] == 4 || [tripletStr length] == 7);
    if([tripletStr length] == 4) {
        tripletStr = [tripletStr mutableCopy];
        [(NSMutableString *)tripletStr insertString:[tripletStr substringWithRange:(NSRange) { 3, 1 }] atIndex:3];
        [(NSMutableString *)tripletStr insertString:[tripletStr substringWithRange:(NSRange) { 2, 1 }] atIndex:2];
        [(NSMutableString *)tripletStr insertString:[tripletStr substringWithRange:(NSRange) { 1, 1 }] atIndex:1];
    }
    long triplet = strtol([tripletStr cStringUsingEncoding:NSASCIIStringEncoding]+1, NULL, 16);
    return CGColorFromHexTriplet((uint32_t)triplet);
}

static NSString *CGColorToHexTriplet(CGColorRef const color, CGFloat *outAlpha)
{
    const CGFloat *rgba = CGColorGetComponents(color);
    if(outAlpha) *outAlpha = rgba[3];
    return [NSString stringWithFormat:@"#%02x%02x%02x", (int)roundf(rgba[0]*255.0),
            (int)roundf(rgba[1]*255.0),
            (int)roundf(rgba[2]*255.0)];
}
