//
//  PocketSVG.m
//
//  Copyright (c) 2013 Ponderwell, Ariel Elkin, and Contributors
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


#import "PocketSVG.h"

NSString * const kPSVGValidCommands = @"CcMmLlHhVvZzqQaAsS";

static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(uint32_t triplet) CF_RETURNS_RETAINED;
static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(NSString *tripletStr) CF_RETURNS_RETAINED;

@interface PSVGParser : NSObject {
    CGMutablePathRef _path;
    CGPoint          _lastControlPoint;
    unichar  _lastCommand;
}

- (CGPathRef)parsePath:(NSString *)attr;
- (void)appendSVGMoveto:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGLineto:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGCurve:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGShorthandCurve:(unichar)cmd withOperands:(NSArray *)operands;
@end

NSArray *PSVGPathsFromSVGString(NSString *svgString, NSMapTable **outAttributes)
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
   
    PSVGParser *parser = [PSVGParser new];
    NSMutableArray *paths = [NSMutableArray new];
    if(outAttributes)
        *outAttributes = [NSMapTable strongToStrongObjectsMapTable];

    NSArray *candidates = [svgString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    for(NSString *candidate in candidates) {
        if(![candidate hasPrefix:@"path "])
            continue;
        
        NSArray *matches = [attrRegex matchesInString:candidate
                                                 options:0
                                                   range:(NSRange) { 0, [candidate length] }];
        
        CGPathRef path = NULL;
        CGColorRef fillColor = NULL, strokeColor = NULL;
        float fillOpacity = 1, strokeOpacity = 1;
        float strokeWidth = 0;
        for(NSTextCheckingResult *match in matches) {
            NSString *attr = [candidate substringWithRange:(NSRange)[match rangeAtIndex:1]];
            NSString *content = [candidate substringWithRange:(NSRange)[match rangeAtIndex:2]];
            
            if([attr isEqualToString:@"d"])
                path = [parser parsePath:content];
            else if(!outAttributes)
                continue;
            else if([attr isEqualToString:@"fill"])
                fillColor = CGColorFromHexTriplet(content);
            else if([attr isEqualToString:@"fill-opacity"])
                fillOpacity = [content floatValue];
            else if([attr isEqualToString:@"stroke"])
                strokeColor = CGColorFromHexTriplet(content);
            else if([attr isEqualToString:@"stroke-opacity"])
                strokeOpacity = [content floatValue];
            else if([attr isEqualToString:@"stroke-width"])
                strokeWidth = [content floatValue];
        }
        if(!path) {
            NSLog(@"*** PocketSVG Error: Invalid/missing d attribute in %@", candidate);
            continue;
        } else {
            [paths addObject:(__bridge id)path];
            if(outAttributes) {
                NSMutableDictionary *attrs = [NSMutableDictionary new];
                if(fillColor) {
                    if(fillOpacity < 1.0)
                        fillColor = CGColorCreateCopyWithAlpha(fillColor, fillOpacity);
                    attrs[@"fillColor"] = (__bridge id)fillColor;
                }
                if(strokeColor) {
                    if(strokeOpacity < 1.0)
                        strokeColor = CGColorCreateCopyWithAlpha(strokeColor, strokeOpacity);
                    attrs[@"strokeColor"] = (__bridge id)strokeColor;
                    attrs[@"strokeWidth"] = @(strokeWidth);
                }
                if([attrs count] > 0)
                    [*outAttributes setObject:attrs forKey:(__bridge id)path];
            }
        }

    }
    return paths;
}

static void _pathWalker(void *info, const CGPathElement *el);

NSString *PSVGFromPaths(NSArray *paths)
{
    NSMutableString * const svg = [@"<svg xmlns=\"http://www.w3.org/2000/svg\""
                                   @" xmlns:xlink=\"http://www.w3.org/1999/xlink\""
                                   @" width=\"100%\" height=\"100%\">\n" mutableCopy];
    
    for(NSUInteger i = 0; i < [paths count]; ++i) {
        [svg appendString:@"  <path d=\""];
        CGPathApply((__bridge CGPathRef)paths[i], (__bridge void *)svg, &_pathWalker);
        [svg appendString:@"\"/>\n"];
    }
    
    [svg appendString:@"</svg>"];
    return svg;

}

static void _pathWalker(void *info, const CGPathElement *el)
{
    NSMutableString *svg = (__bridge id)info;
    
    switch(el->type) {
        case kCGPathElementMoveToPoint:
            [svg appendFormat:@"M%.3g,%.3g", el->points[0].x, el->points[0].y];
            break;
        case kCGPathElementAddLineToPoint:
            [svg appendFormat:@"L%.3g,%.3g", el->points[0].x, el->points[0].y];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            [svg appendFormat:@"Q%.3g,%.3g,%.3g,%.3g", el->points[0].x, el->points[0].y,
                                                       el->points[1].x, el->points[1].y];
            break;
        case kCGPathElementAddCurveToPoint:
            [svg appendFormat:@"C%.3g,%.3g,%.3g,%.3g,%.3g,%.3g", el->points[0].x, el->points[0].y,
                                                                 el->points[1].x, el->points[1].y,
                                                                 el->points[2].x, el->points[2].y];
            break;
        case kCGPathElementCloseSubpath:
            [svg appendFormat:@"Z"];
            break;
	}
}



@implementation PSVGParser

- (CGPathRef)parsePath:(NSString *)attr
{
#ifdef PSVG_DEBUG
    NSLog(@"d=%@", attr);
#endif
    _path = CGPathCreateMutable();
    CGPathMoveToPoint(_path, NULL, 0, 0);
    
    NSScanner *scanner = [NSScanner scannerWithString:attr];
    NSMutableCharacterSet *separators = [NSMutableCharacterSet characterSetWithCharactersInString:@","];
    [separators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    scanner.charactersToBeSkipped = separators;
    
    NSCharacterSet *commands = [NSCharacterSet characterSetWithCharactersInString:kPSVGValidCommands];
    
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
        NSLog(@"*** PocketSVG parse error at index: %d: '%c'",
              (int)scanner.scanLocation, [attr characterAtIndex:scanner.scanLocation]);
    
    return _path;
}

- (void)handleCommand:(unichar)opcode withOperands:(NSArray *)operands
{
#ifdef PSVG_DEBUG
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
            NSLog(@"*** PocketSVG Error: Elliptical arcs not supported"); // TODO
            break;
        case 'Z':
        case 'z':
            CGPathCloseSubpath(_path);
            break;
        default:
            NSLog(@"*** PocketSVG Error: Cannot process command : '%c'", opcode);
            break;
    }
    _lastCommand         = opcode;
}

- (void)appendSVGMoveto:(unichar)cmd withOperands:(NSArray *)operands
{
    if ([operands count]%2 != 0) {
        NSLog(@"*** PocketSVG Error: Invalid parameter count in M style token");
        return;
    }
    
    for(NSUInteger i = 0; i < [operands count]; ++i) {
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat x = [operands[i++] floatValue] + (cmd == 'm' ? currentPoint.x : 0);
        CGFloat y = [operands[i]   floatValue] + (cmd == 'm' ? currentPoint.y : 0);

        if (i == 1) {
            CGPathMoveToPoint(_path, NULL, x, y);
        }
        else {
            CGPathAddLineToPoint(_path, NULL, x, y);
        }
    }
}

- (void)appendSVGLineto:(unichar)cmd withOperands:(NSArray *)operands
{
    for(NSUInteger i = 0; i < [operands count]; ++i) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        switch (cmd) {
            case 'l':
                x = currentPoint.x;
                y = currentPoint.y;
            case 'L':
                x += [operands[i] floatValue];
                if (++i == [operands count]) {
                    NSLog(@"*** PocketSVG Error: Invalid parameter count in L style token");
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
                NSLog(@"*** PocketSVG Error: Unrecognised L style command.");
                return;
        }
        CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

- (void)appendSVGCurve:(unichar)cmd withOperands:(NSArray *)operands
{
    if([operands count]%6 != 0) {
        NSLog(@"*** PocketSVG Error: Invalid number of parameters for C command");
        return;
    }
    
    // (x1, y1, x2, y2, x, y)
    for(NSUInteger i = 0; i < [operands count]; i += 6) {
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat x1 = [operands[i+0] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat y1 = [operands[i+1] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        CGFloat x2 = [operands[i+2] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat y2 = [operands[i+3] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        CGFloat x  = [operands[i+4] floatValue] + (cmd == 'c' ? currentPoint.x : 0);
        CGFloat y  = [operands[i+5] floatValue] + (cmd == 'c' ? currentPoint.y : 0);
        
        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

- (void)appendSVGShorthandCurve:(unichar)cmd withOperands:(NSArray *)operands
{
    if([operands count]%4 != 0) {
        NSLog(@"*** PocketSVG Error: Invalid number of parameters for S command");
        return;
    }
    if(_lastCommand != 'C' && _lastCommand != 'c' && _lastCommand != 'S' && _lastCommand != 's')
        _lastControlPoint = CGPathGetCurrentPoint(_path);
    
    // (x2, y2, x, y)
    for(NSUInteger i = 0; i < [operands count]; i += 4) {
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat x1 = currentPoint.x + (currentPoint.x - _lastControlPoint.x);
        CGFloat y1 = currentPoint.y + (currentPoint.y - _lastControlPoint.y);
        CGFloat x2 = [operands[i+0] floatValue] + (cmd == 's' ? currentPoint.x : 0);
        CGFloat y2 = [operands[i+1] floatValue] + (cmd == 's' ? currentPoint.y : 0);
        CGFloat x  = [operands[i+2] floatValue] + (cmd == 's' ? currentPoint.x : 0);
        CGFloat y  = [operands[i+3] floatValue] + (cmd == 's' ? currentPoint.y : 0);

        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

@end


#pragma mark -

#if TARGET_OS_IPHONE
@implementation UIBezierPath (PocketSVG)

+ (NSArray *)ps_pathsFromContentsOfSVGFile:(NSString * const)aPath
{
    BOOL isDir;
    NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && !isDir);
    return [self ps_pathsFromSVGString:[NSString stringWithContentsOfFile:aPath usedEncoding:NULL error:nil]];
}

+ (NSArray *)ps_pathsFromSVGString:(NSString *)svgString
{
    NSArray *pathRefs = PSVGPathsFromSVGString(svgString, NULL);
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:pathRefs.count];
    for(id pathRef in pathRefs) {
        [paths addObject:[UIBezierPath bezierPathWithCGPath:(__bridge CGPathRef)pathRef]];
    }
    return paths;
}

- (NSString *)ps_SVGRepresentation
{
    return PSVGFromPaths(@[(__bridge id)self.CGPath]);
}
@end
#endif

static __attribute__((overloadable)) CGColorRef CGColorFromHexTriplet(uint32_t triplet)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef color = CGColorCreate(colorSpace,
                         (CGFloat[]) {
                             ((float)((triplet & 0xFF0000) >> 16))/255.0,
                             ((float)((triplet & 0xFF00) >> 8))/255.0,
                             ((float)(triplet & 0xFF))/255.0,
                             1
                         });
    CFRelease(colorSpace);
    return color;
}

static __attribute__((overloadable)) CF_RETURNS_RETAINED CGColorRef CGColorFromHexTriplet(NSString *tripletStr)
{
    NSCParameterAssert([tripletStr hasPrefix:@"#"]);
    NSCParameterAssert([tripletStr length] == 3 || [tripletStr length] == 7);
    if([tripletStr length] == 3) {
        tripletStr = [tripletStr mutableCopy];
        [(NSMutableString *)tripletStr insertString:@"0" atIndex:5];
        [(NSMutableString *)tripletStr insertString:@"0" atIndex:3];
        [(NSMutableString *)tripletStr insertString:@"0" atIndex:1];
    }
    uint32_t triplet = strtol([tripletStr cStringUsingEncoding:NSASCIIStringEncoding]+1,
                              NULL, 16);
    return CGColorFromHexTriplet(triplet);
}