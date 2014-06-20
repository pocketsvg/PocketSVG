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

NSString * const commandCharString   = @"CcMmLlHhVvZzqQaAsS";

@interface PSVGParser : NSObject {
    float            _pathScale;
    CGMutablePathRef _path;
    CGPoint          _lastPoint;
    CGPoint          _lastControlPoint;
    BOOL             _validLastControlPoint;
    NSCharacterSet  *_commandSet;
}
@property(nonatomic, readonly) CGPathRef path;

- (instancetype)initWithSVGPathNodeDAttr:(NSString *)attr;
- (void)parsePath:(NSString *)attr;
- (void)appendSVGMCommand:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGLCommand:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGCCommand:(unichar)cmd withOperands:(NSArray *)operands;
- (void)appendSVGSCommand:(unichar)cmd withOperands:(NSArray *)operands;
@end


NSArray *PSVGPathsFromSVGString(NSString *svgString)
{
    NSRegularExpression *dStringRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"[^\\w]d=\"([^\"]+)\""
                                         options:NSRegularExpressionCaseInsensitive
                                         error:nil];
    NSArray *matches = [dStringRegex matchesInString:svgString
                                             options:0
                                               range:(NSRange) { 0, svgString.length }];
    
    if([matches count] == 0) {
        NSLog(@"*** PocketSVG Error: No d attributes found in SVG file.");
        return nil;
    }
    NSMutableArray *dStrings = [NSMutableArray arrayWithCapacity:[matches count]];
    for(NSTextCheckingResult *match in matches) {
        NSString *str = [svgString substringWithRange:(NSRange)[match rangeAtIndex:1]];
        [dStrings addObject:str];
    }
    
    NSMutableArray *result = [NSMutableArray new];
    for(NSString *dAttr in dStrings) {
        CGPathRef path = [[[PSVGParser alloc] initWithSVGPathNodeDAttr:dAttr] path];
        if(!path)
            NSLog(@"*** PocketSVG Error: Invalid d attribute: `%@`", dAttr);
        else
            [result addObject:(__bridge id)path];
    }
    return result;
}

static void _pathWalker(void *info, const CGPathElement *el);

NSString *PSVGFromPaths(NSArray *paths)
{
    NSMutableString * const svg = [@"<svg xmlns=\"http://www.w3.org/2000/svg\""
                                   @" xmlns:xlink=\"http://www.w3.org/1999/xlink\""
                                   @" width=\"100%\" height=\"100%\">\n" mutableCopy];
    
    // Build polylines, simplify them if necessary and append to the SVG output
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
            [svg appendFormat:@"M%f,%f", el->points[0].x, el->points[0].y];
            break;
        case kCGPathElementAddLineToPoint:
            [svg appendFormat:@"L%f,%f", el->points[0].x, el->points[0].y];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            [svg appendFormat:@"Q%f,%f,%f,%f", el->points[0].x, el->points[0].y,
                                               el->points[1].x, el->points[1].y];
            break;
        case kCGPathElementAddCurveToPoint:
            [svg appendFormat:@"C%f,%f,%f,%f,%f,%f", el->points[0].x, el->points[0].y,
                                                     el->points[1].x, el->points[1].y,
                                                     el->points[2].x, el->points[2].y];
            break;
        case kCGPathElementCloseSubpath:
            [svg appendFormat:@"Z"];
            break;
	}
}



@implementation PSVGParser

- (instancetype)initWithSVGPathNodeDAttr:(NSString *)attr
{
    if((self = [super init])) {
        _path = CGPathCreateMutable();
        
        _lastPoint = CGPointMake(0, 0);
        _validLastControlPoint = NO;
        _pathScale = 0;
        _commandSet   = [NSCharacterSet characterSetWithCharactersInString:commandCharString];
        [self parsePath:attr];
    }
    return self;
}


#pragma mark - Private methods

- (void)parsePath:(NSString *)attr
{
#ifdef DEBUG
    NSLog(@"d=%@", attr);
#endif
    NSScanner *scanner = [NSScanner scannerWithString:attr];
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@",\t"];
    
    NSMutableArray *operands = [NSMutableArray new];
    NSString *cmd;
    while([scanner scanCharactersFromSet:_commandSet intoString:&cmd]) {
        if([cmd length] > 1) {
            scanner.scanLocation -= [cmd length]-1;
        } else {
            float operand;
            [scanner scanCharactersFromSet:separators intoString:NULL];
            while([scanner scanFloat:&operand]) {
                [operands addObject:@(operand)];
                [scanner scanCharactersFromSet:separators intoString:NULL];
            }
        }
        [self handleCommand:[cmd characterAtIndex:0] withOperands:operands];
        [operands removeAllObjects];
    }
    if(scanner.scanLocation < [attr length])
        NSLog(@"*** PocketSVG parse error at index: %d: '%c'",
              (int)scanner.scanLocation, [attr characterAtIndex:scanner.scanLocation]);
}

- (void)handleCommand:(unichar)opcode withOperands:(NSArray *)operands
{
#ifdef DEBUG
    NSLog(@"%c %@", opcode, operands);
#endif
    switch (opcode) {
        case 'M':
        case 'm':
            [self appendSVGMCommand:opcode withOperands:operands];
            break;
        case 'L':
        case 'l':
        case 'H':
        case 'h':
        case 'V':
        case 'v':
            [self appendSVGLCommand:opcode withOperands:operands];
            break;
        case 'C':
        case 'c':
            [self appendSVGCCommand:opcode withOperands:operands];
            break;
        case 'S':
        case 's':
            [self appendSVGSCommand:opcode withOperands:operands];
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
}

- (void)appendSVGMCommand:(unichar)cmd withOperands:(NSArray *)operands
{
    _validLastControlPoint = NO;
    if ([operands count]%2 != 0) {
        NSLog(@"*** PocketSVG Error: Invalid parameter count in M style token");
        return;
    }
    
    for(NSUInteger i = 0; i < [operands count]; ++i) {
        CGFloat x = [operands[i++] floatValue] + (cmd == 'm' ? _lastPoint.x : 0);
        CGFloat y = [operands[i]   floatValue] + (cmd == 'm' ? _lastPoint.y : 0);
        _lastPoint = CGPointMake(x, y);
        if (i == 1) {
            CGPathMoveToPoint(_path, NULL, x, y);
        }
        else {
            CGPathAddLineToPoint(_path, NULL, x, y);
        }
    }
}

- (void)appendSVGLCommand:(unichar)cmd withOperands:(NSArray *)operands
{
    _validLastControlPoint = NO;
    for(NSUInteger i = 0; i < [operands count]; ++i) {
        CGFloat x = 0;
        CGFloat y = 0;
        switch (cmd) {
            case 'l':
                x = _lastPoint.x;
                y = _lastPoint.y;
            case 'L':
                x += [operands[i] floatValue];
                if (++i == [operands count]) {
                    NSLog(@"*** PocketSVG Error: Invalid parameter count in L style token");
                    return;
                }
                y += [operands[i] floatValue];
                break;
            case 'h' :
                x = _lastPoint.x;                
            case 'H' :
                x += [operands[i] floatValue];
                y = _lastPoint.y;
                break;
            case 'v' :
                y = _lastPoint.y;
            case 'V' :
                y += [operands[i] floatValue];
                x = _lastPoint.x;
                break;
            default:
                NSLog(@"*** PocketSVG Error: Unrecognised L style command.");
                return;
        }
        _lastPoint = CGPointMake(x, y);
        CGPathAddLineToPoint(_path, NULL, x, y);
    }
}

- (void)appendSVGCCommand:(unichar)cmd withOperands:(NSArray *)operands
{
    if([operands count] != 6) {
        NSLog(@"*** PocketSVG Error: Insufficient parameters for C command");
        return;
    }
    
    // (x1, y1, x2, y2, x, y)
    CGFloat x1 = [operands[0] floatValue] + (cmd == 'c' ? _lastPoint.x : 0);
    CGFloat y1 = [operands[1] floatValue] + (cmd == 'c' ? _lastPoint.y : 0);
    CGFloat x2 = [operands[2] floatValue] + (cmd == 'c' ? _lastPoint.x : 0);
    CGFloat y2 = [operands[3] floatValue] + (cmd == 'c' ? _lastPoint.y : 0);
    CGFloat x  = [operands[4] floatValue] + (cmd == 'c' ? _lastPoint.x : 0);
    CGFloat y  = [operands[5] floatValue] + (cmd == 'c' ? _lastPoint.y : 0);
    _lastPoint = CGPointMake(x, y);
    CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
    _lastControlPoint = CGPointMake(x2, y2);
    _validLastControlPoint = YES;
}

- (void)appendSVGSCommand:(unichar)cmd withOperands:(NSArray *)operands
{
    if (!_validLastControlPoint) {
        NSLog(@"*** PocketSVG Error: Invalid last control point in S command");
    } else if([operands count] != 4) {
        NSLog(@"*** PocketSVG Error: Insufficient parameters for S command");
        return;
    }
    
    // (x2, y2, x, y)
    CGFloat x1 = _lastPoint.x + (_lastPoint.x - _lastControlPoint.x);
    CGFloat y1 = _lastPoint.y + (_lastPoint.y - _lastControlPoint.y);
    CGFloat x2 = [operands[0] floatValue] + (cmd == 's' ? _lastPoint.x : 0);
    CGFloat y2 = [operands[1] floatValue] + (cmd == 's' ? _lastPoint.y : 0);
    CGFloat x  = [operands[2] floatValue] + (cmd == 's' ? _lastPoint.x : 0);
    CGFloat y  = [operands[3] floatValue] + (cmd == 's' ? _lastPoint.y : 0);
    _lastPoint = CGPointMake(x, y);
    CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
    _lastControlPoint = CGPointMake(x2, y2);
    _validLastControlPoint = YES;
}

@end


#pragma mark -

#if TARGET_OS_IPHONE
@implementation UIBezierPath (PocketSVG)
+ (NSArray *)ps_pathsFromSVGString:(NSString *)svgString
{
    NSArray *pathRefs = PSVGPathsFromSVGString(svgString);
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
