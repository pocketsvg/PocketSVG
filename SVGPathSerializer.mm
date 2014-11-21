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
#import <vector>

NSString * const kValidSVGCommands = @"CcMmLlHhVvZzqQaAsS";

struct pathDefinitionParser {
public:
    CGPathRef parse(NSString *definition);

protected:
    CGMutablePathRef _path;
    CGPoint _lastControlPoint;
    unichar _cmd, _lastCmd;
    std::vector<float> _operands;

    void appendMoveTo();
    void appendLineTo();
    void appendCurve();
    void appendShorthandCurve();
};

struct hexTriplet {
    hexTriplet(uint32_t);
    hexTriplet(NSString *stringRepresentation);
    hexTriplet(CGColorRef color);

    CGColorRef CGColor();
    NSString *string();

protected:
    uint32_t _data;
};

static NSDictionary *parseStyle(NSString *body);

#pragma mark -

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
        pathDefinitionParser parser;
        for(NSTextCheckingResult *match in matches) {
            NSString * const attr    = [candidate substringWithRange:(NSRange)[match rangeAtIndex:1]],
                     * const content = [candidate substringWithRange:(NSRange)[match rangeAtIndex:2]];
            
            if([attr isEqualToString:@"d"])
                path = parser.parse(content);
            else if(!outAttributes)
                continue;
            else if([attr isEqualToString:@"style"])
                [attrs addEntriesFromDictionary:parseStyle(content)];
            else
                attrs[attr] = content;
        }
        for(NSString *attr in attrs.allKeys) {
            if([attr isEqualToString:@"fill"] || [attr isEqualToString:@"stroke"]) {
                if([attrs[attr] isEqualToString:@"none"]) {
                    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
                    attrs[attr] = (__bridge id)CGColorCreate(colorSpace, (CGFloat[]) { 1, 1, 1, 0 });
                    CFRelease(colorSpace);
                } else
                    attrs[attr] = (__bridge id)hexTriplet(attrs[attr]).CGColor();
            }
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

NSString *SVGStringFromCGPaths(NSArray * const paths, NSMapTable * const attributes)
{
    static NSNumberFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [NSNumberFormatter new];
        fmt.numberStyle = NSNumberFormatterDecimalStyle;
        fmt.maximumSignificantDigits = 3;
    });

    CGRect bounds = CGRectZero;
    NSMutableString * const svg = [NSMutableString new];
    for(id path in paths) {
        bounds = CGRectUnion(bounds, CGPathGetBoundingBox((__bridge CGPathRef)path));
        
        [svg appendString:@"  <path"];
        NSDictionary *pathAttrs = [attributes objectForKey:path];
        for(NSString *key in pathAttrs) {
            if(![pathAttrs[key] isKindOfClass:[NSString class]]) { // Color
                [svg appendFormat:@" %@=\"%@\"", key, hexTriplet((__bridge CGColorRef)pathAttrs[key]).string()];
                
                float const alpha = CGColorGetAlpha((__bridge CGColorRef)pathAttrs[key]);
                if(alpha < 1.0)
                    [svg appendFormat:@" %@-opacity=\"%.2g\"", key, alpha];
            } else
                [svg appendFormat:@" %@=\"%@\"", key, pathAttrs[key]];
        }
        [svg appendString:@" d=\""];
        CGPathApply((__bridge CGPathRef)path, (__bridge void *)svg,
                    [](void * const info, const CGPathElement * const el)
        {
            NSMutableString * const svg = (__bridge id)info;
            
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
        });
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

CGPathRef pathDefinitionParser::parse(NSString *definition)
{
#ifdef SVG_PATH_SERIALIZER_DEBUG
    NSLog(@"d=%@", attr);
#endif
    _path = CGPathCreateMutable();
    CGPathMoveToPoint(_path, NULL, 0, 0);

    NSScanner * const scanner = [NSScanner scannerWithString:definition];
    NSMutableCharacterSet * const separators = [NSMutableCharacterSet characterSetWithCharactersInString:@","];
    [separators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    scanner.charactersToBeSkipped = separators;

    NSCharacterSet * const commands = [NSCharacterSet characterSetWithCharactersInString:kValidSVGCommands];

    NSString *cmdBuf;
    while([scanner scanCharactersFromSet:commands intoString:&cmdBuf]) {
        _operands.clear();
        if([cmdBuf length] > 1) {
            scanner.scanLocation -= [cmdBuf length]-1;
        } else {
            for(float operand;
                [scanner scanFloat:&operand];
                _operands.push_back(operand));
        }
#ifdef SVG_PATH_SERIALIZER_DEBUG
        NSLog(@"%c %@", opcode, operands);
#endif
        _lastCmd = _cmd;
        _cmd = [cmdBuf characterAtIndex:0];
        switch(_cmd) {
            case 'M': case 'm':
                appendMoveTo();
                break;
            case 'L': case 'l':
            case 'H': case 'h':
            case 'V': case 'v':
                appendLineTo();
                break;
            case 'C': case 'c':
                appendCurve();
                break;
            case 'S': case 's':
                appendShorthandCurve();
                break;
            case 'a': case 'A':
                NSLog(@"*** Error: Elliptical arcs not supported"); // TODO
                break;
            case 'Z': case 'z':
                CGPathCloseSubpath(_path);
                break;
            default:
                NSLog(@"*** Error: Cannot process command : '%c'", _cmd);
                break;
        }
    }
    if(scanner.scanLocation < [definition length])
        NSLog(@"*** SVG parse error at index: %d: '%c'",
              (int)scanner.scanLocation, [definition characterAtIndex:scanner.scanLocation]);

    return _path;
}

void pathDefinitionParser::appendMoveTo()
{
    if(_operands.size()%2 != 0) {
        NSLog(@"*** Error: Invalid parameter count in M style token");
        return;
    }
    
    for(NSUInteger i = 0; i < _operands.size(); i += 2) {
        CGPoint currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat x = _operands[i+0] + (_cmd == 'm' ? currentPoint.x : 0);
        CGFloat y = _operands[i+1] + (_cmd == 'm' ? currentPoint.y : 0);

        if(i == 0)
            CGPathMoveToPoint(_path, NULL, x, y);
        else
            CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

void pathDefinitionParser::appendLineTo()
{
    for(NSUInteger i = 0; i < _operands.size(); ++i) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        switch(_cmd) {
            case 'l':
                x = currentPoint.x;
                y = currentPoint.y;
            case 'L':
                x += _operands[i];
                if (++i == _operands.size()) {
                    NSLog(@"*** Error: Invalid parameter count in L style token");
                    return;
                }
                y += _operands[i];
                break;
            case 'h' :
                x = currentPoint.x;
            case 'H' :
                x += _operands[i];
                y = currentPoint.y;
                break;
            case 'v' :
                y = currentPoint.y;
            case 'V' :
                y += _operands[i];
                x = currentPoint.x;
                break;
            default:
                NSLog(@"*** Error: Unrecognised L style command.");
                return;
        }
        CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

void pathDefinitionParser::appendCurve()
{
    if(_operands.size()%6 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for C command");
        return;
    }
    
    // (x1, y1, x2, y2, x, y)
    for(NSUInteger i = 0; i < _operands.size(); i += 6) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = _operands[i+0] + (_cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y1 = _operands[i+1] + (_cmd == 'c' ? currentPoint.y : 0);
        CGFloat const x2 = _operands[i+2] + (_cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y2 = _operands[i+3] + (_cmd == 'c' ? currentPoint.y : 0);
        CGFloat const x  = _operands[i+4] + (_cmd == 'c' ? currentPoint.x : 0);
        CGFloat const y  = _operands[i+5] + (_cmd == 'c' ? currentPoint.y : 0);
        
        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

void pathDefinitionParser::appendShorthandCurve()
{
    if(_operands.size()%4 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for S command");
        return;
    }
    if(_lastCmd != 'C' && _lastCmd != 'c' && _lastCmd != 'S' && _lastCmd != 's')
        _lastControlPoint = CGPathGetCurrentPoint(_path);
    
    // (x2, y2, x, y)
    for(NSUInteger i = 0; i < _operands.size(); i += 4) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = currentPoint.x + (currentPoint.x - _lastControlPoint.x);
        CGFloat const y1 = currentPoint.y + (currentPoint.y - _lastControlPoint.y);
        CGFloat const x2 = _operands[i+0] + (_cmd == 's' ? currentPoint.x : 0);
        CGFloat const y2 = _operands[i+1] + (_cmd == 's' ? currentPoint.y : 0);
        CGFloat const x  = _operands[i+2] + (_cmd == 's' ? currentPoint.x : 0);
        CGFloat const y  = _operands[i+3] + (_cmd == 's' ? currentPoint.y : 0);

        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
    }
}

hexTriplet::hexTriplet(NSString *stringRepresentation)
{
    NSCParameterAssert([stringRepresentation hasPrefix:@"#"]);
    NSCParameterAssert([stringRepresentation length] == 4 || [stringRepresentation length] == 7);
    if([stringRepresentation length] == 4) {
        stringRepresentation = [stringRepresentation mutableCopy];
        [(NSMutableString *)stringRepresentation insertString:[stringRepresentation substringWithRange:(NSRange) { 3, 1 }] atIndex:3];
        [(NSMutableString *)stringRepresentation insertString:[stringRepresentation substringWithRange:(NSRange) { 2, 1 }] atIndex:2];
        [(NSMutableString *)stringRepresentation insertString:[stringRepresentation substringWithRange:(NSRange) { 1, 1 }] atIndex:1];
    }
    _data = (uint32_t)strtol([stringRepresentation cStringUsingEncoding:NSASCIIStringEncoding]+1, NULL, 16);
}

hexTriplet::hexTriplet(CGColorRef const color)
{
    const CGFloat * const rgba = CGColorGetComponents(color);
    _data = (((uint8_t)roundf(rgba[0] * 255) & 0xff) << 16)
          | (((uint8_t)roundf(rgba[1] * 255) & 0xff) << 8)
          | ( (uint8_t)roundf(rgba[2] * 255) & 0xff);
}

CGColorRef hexTriplet::CGColor()
{
    CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef const color = CGColorCreate(colorSpace,
                                           (CGFloat[]) {
                                               ((_data & 0xFF0000) >> 16) / (CGFloat)255.0,
                                               ((_data & 0x00FF00) >> 8)  / (CGFloat)255.0,
                                               ((_data & 0x0000FF))       / (CGFloat)255.0,
                                               1
                                           });
    CFRelease(colorSpace);
    return color;
}

NSString *hexTriplet::string()
{
    return [NSString stringWithFormat:@"#%02x%02x%02x",
            (_data & 0xFF0000) >> 16,
            (_data & 0x00FF00) >> 8,
            (_data & 0x0000FF)];
}

static NSDictionary *parseStyle(NSString * const body)
{
    NSScanner * const scanner = [NSScanner scannerWithString:body];
    NSMutableCharacterSet * const separators = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [separators addCharactersInString:@":;"];
    scanner.charactersToBeSkipped = separators;

    NSMutableDictionary * const style = [NSMutableDictionary new];
    NSString *key, *value;
    while([scanner scanUpToString:@":" intoString:&key]) {
        if(![scanner scanUpToString:@";" intoString:&value]) {
            NSLog(@"Parse error in style: '%@'", body);
            return nil;
        }
        style[key] = value;
    }
    return style;
}

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
