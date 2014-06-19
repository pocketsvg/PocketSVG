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

NSInteger  const maxPathComplexity   = 1000;
NSInteger  const maxParameters       = 64;
NSInteger  const maxTokenLength      = 64;
NSString * const separatorCharString = @"-, CcMmLlHhVvZzqQaAsS";
NSString * const commandCharString   = @"CcMmLlHhVvZzqQaAsS";
unichar    const invalidCommand      = '*';

@class PSVGToken;
@interface PSVGParser : NSObject {
    float            _pathScale;
    CGMutablePathRef _path;
    CGPoint          _lastPoint;
    CGPoint          _lastControlPoint;
    BOOL             _validLastControlPoint;
    NSCharacterSet  *_separatorSet;
    NSCharacterSet  *_commandSet;
    
    NSMutableArray  *_tokens;
}
@property(nonatomic, readonly) CGPathRef path;

- (id)initWithSVGPathNodeDAttr:(NSString *)attr;
- (NSMutableArray *)parsePath:(NSString *)attr;
- (CGMutablePathRef)generateBezier:(NSArray *)tokens;
- (void)reset;
- (void)appendSVGMCommand:(PSVGToken *)token;
- (void)appendSVGLCommand:(PSVGToken *)token;
- (void)appendSVGCCommand:(PSVGToken *)token;
- (void)appendSVGSCommand:(PSVGToken *)token;
@end

@interface PSVGToken : NSObject {
    unichar          _command;
    NSMutableArray  *_values;
}
@property(nonatomic, assign) unichar command;

- (id)initWithCommand:(unichar)commandChar;
- (void)addValue:(CGFloat)value;
- (CGFloat)parameter:(NSInteger)index;
- (NSInteger)valence;
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
        [dStrings addObject:[str stringByReplacingOccurrencesOfString:@"[\\s\\n\\t]"
                                                           withString:@""
                                                              options:NSRegularExpressionSearch
                                                                range:(NSRange) { 0, [str length] }]];
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

@implementation PSVGToken

- (id)initWithCommand:(unichar)commandChar {
    self = [self init];
    if (self) {
        _command = commandChar;
        _values = [[NSMutableArray alloc] initWithCapacity:maxParameters];
    }
    return self;
}

- (void)addValue:(CGFloat)value {
    [_values addObject:[NSNumber numberWithDouble:value]];
}

- (CGFloat)parameter:(NSInteger)index {
    return [[_values objectAtIndex:index] doubleValue];
}

- (NSInteger)valence
{
    return [_values count];
}

@end


@implementation PSVGParser

- (id)initWithSVGPathNodeDAttr:(NSString *)attr
{
    if((self = [super init])) {
        [self reset];
        _pathScale = 0;
        _separatorSet = [NSCharacterSet characterSetWithCharactersInString:separatorCharString];
        _commandSet = [NSCharacterSet characterSetWithCharactersInString:commandCharString];
        _tokens = [self parsePath:attr];
        _path = [self generateBezier:_tokens];
    }
    return self;
}


#pragma mark - Private methods

/*
    Tokenise pseudocode, used in parsePath below

    start a token
    eat a character
    while more characters to eat
        add character to token
        while in a token and more characters to eat
            eat character
            add character to token
        add completed token to store
        start a new token
    throw away empty token
*/

- (NSMutableArray *)parsePath:(NSString *)attr
{
    NSMutableArray *stringTokens = [NSMutableArray arrayWithCapacity:maxPathComplexity];
    
    NSInteger index = 0;
    while (index < [attr length]) {
        unichar    charAtIndex = [attr characterAtIndex:index];
        //Jagie:Skip whitespace
        if (charAtIndex == 32) {
            index ++;
            continue;
        }
        NSMutableString *stringToken = [[NSMutableString alloc] initWithCapacity:maxTokenLength];
        [stringToken setString:@""];
        
        if (charAtIndex != ',') {
            [stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
        }
        if (![_commandSet characterIsMember:charAtIndex] && charAtIndex != ',') {
            while ( (++index < [attr length]) && ![_separatorSet characterIsMember:(charAtIndex = [attr characterAtIndex:index])] ) {
                [stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
            }
        }
        else {
            index++;
        }
        
        if ([stringToken length]) {
            [stringTokens addObject:stringToken];
        }
    }
    
    if ([stringTokens count] == 0) {
        NSLog(@"*** PocketSVG Error: Path string is empty of tokens");
        return nil;
    }
    
    // turn the stringTokens array into Tokens, checking validity of tokens as we go
    _tokens = [[NSMutableArray alloc] initWithCapacity:maxPathComplexity];
    index = 0;
    NSString *stringToken = [stringTokens objectAtIndex:index];
    unichar command = [stringToken characterAtIndex:0];
    while (index < [stringTokens count]) {
        if (![_commandSet characterIsMember:command]) {
            NSLog(@"*** PocketSVG Error: Path string parse error: found float where expecting command at token %ld in path %s.",
                    (long)index, [attr cStringUsingEncoding:NSUTF8StringEncoding]);
            return nil;
        }
        PSVGToken *token = [[PSVGToken alloc] initWithCommand:command];
        
        // There can be any number of floats after a command. Suck them in until the next command.
        while ((++index < [stringTokens count]) && ![_commandSet characterIsMember:
                (command = [(stringToken = [stringTokens objectAtIndex:index]) characterAtIndex:0])]) {
            
            NSScanner *floatScanner = [NSScanner scannerWithString:stringToken];
            float value;
            if (![floatScanner scanFloat:&value]) {
                NSLog(@"*** PocketSVG Error: Path string parse error: expected float or command at token %ld (but found %s) in path %s.",
                      (long)index, [stringToken cStringUsingEncoding:NSUTF8StringEncoding], [attr cStringUsingEncoding:NSUTF8StringEncoding]);
                return nil;
            }
            // Maintain scale.
            _pathScale = (abs(value) > _pathScale) ? abs(value) : _pathScale;
            [token addValue:value];
        }
        
        // now we've reached a command or the end of the stringTokens array
        [_tokens    addObject:token];
    }
    //[stringTokens release];
    return _tokens;
}

- (CGMutablePathRef)generateBezier:(NSArray *)inTokens
{
    _path = CGPathCreateMutable();

    [self reset];
    for (PSVGToken *thisToken in inTokens) {
        unichar command = [thisToken command];
        switch (command) {
            case 'M':
            case 'm':
                [self appendSVGMCommand:thisToken];
                break;
            case 'L':
            case 'l':
            case 'H':
            case 'h':
            case 'V':
            case 'v':
                [self appendSVGLCommand:thisToken];
                break;
            case 'C':
            case 'c':
                [self appendSVGCCommand:thisToken];
                break;
            case 'S':
            case 's':
                [self appendSVGSCommand:thisToken];
                break;
            case 'Z':
            case 'z':
                CGPathCloseSubpath(_path);
                break;
            default:
                NSLog(@"*** PocketSVG Error: Cannot process command : '%c'", command);
                break;
        }
    }
    return _path;
}

- (void)reset
{
    _lastPoint = CGPointMake(0, 0);
    _validLastControlPoint = NO;
}

- (void)appendSVGMCommand:(PSVGToken *)token
{
    _validLastControlPoint = NO;
    NSInteger index = 0;
    BOOL first = YES;
    while (index < [token valence]) {
        CGFloat x = [token parameter:index] + ([token command] == 'm' ? _lastPoint.x : 0);
        if (++index == [token valence]) {
            NSLog(@"*** PocketSVG Error: Invalid parameter count in M style token");
            return;
        }
        CGFloat y = [token parameter:index] + ([token command] == 'm' ? _lastPoint.y : 0);
        _lastPoint = CGPointMake(x, y);
        if (first) {
            CGPathMoveToPoint(_path, NULL, x, y);
            first = NO;
        }
        else {
            CGPathAddLineToPoint(_path, NULL, x, y);
        }
        index++;
    }
}

- (void)appendSVGLCommand:(PSVGToken *)token
{
    _validLastControlPoint = NO;
    NSInteger index = 0;
    while (index < [token valence]) {
        CGFloat x = 0;
        CGFloat y = 0;
        switch ( [token command] ) {
            case 'l':
                x = _lastPoint.x;
                y = _lastPoint.y;
            case 'L':
                x += [token parameter:index];
                if (++index == [token valence]) {
                    NSLog(@"*** PocketSVG Error: Invalid parameter count in L style token");
                    return;
                }
                y += [token parameter:index];
                break;
            case 'h' :
                x = _lastPoint.x;                
            case 'H' :
                x += [token parameter:index];
                y = _lastPoint.y;
                break;
            case 'v' :
                y = _lastPoint.y;
            case 'V' :
                y += [token parameter:index];
                x = _lastPoint.x;
                break;
            default:
                NSLog(@"*** PocketSVG Error: Unrecognised L style command.");
                return;
        }
        _lastPoint = CGPointMake(x, y);
        CGPathAddLineToPoint(_path, NULL, x, y);
        index++;
    }
}

- (void)appendSVGCCommand:(PSVGToken *)token
{
    NSInteger index = 0;
    while ((index + 5) < [token valence]) {  // we must have 6 floats here (x1, y1, x2, y2, x, y).
        CGFloat x1 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
        CGFloat y1 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
        CGFloat x2 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
        CGFloat y2 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
        CGFloat x  = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
        CGFloat y  = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
        _lastPoint = CGPointMake(x, y);
        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
        _validLastControlPoint = YES;
    }
    if (index == 0) {
        NSLog(@"*** PocketSVG Error: Insufficient parameters for C command");
    }
}

- (void)appendSVGSCommand:(PSVGToken *)token
{
    if (!_validLastControlPoint) {
        NSLog(@"*** PocketSVG Error: Invalid last control point in S command");
    }
    NSInteger index = 0;
    while ((index + 3) < [token valence]) {  // we must have 4 floats here (x2, y2, x, y).
        CGFloat x1 = _lastPoint.x + (_lastPoint.x - _lastControlPoint.x); // + ([token command] == 's' ? lastPoint.x : 0);
        CGFloat y1 = _lastPoint.y + (_lastPoint.y - _lastControlPoint.y); // + ([token command] == 's' ? lastPoint.y : 0);
        CGFloat x2 = [token parameter:index++] + ([token command] == 's' ? _lastPoint.x : 0);
        CGFloat y2 = [token parameter:index++] + ([token command] == 's' ? _lastPoint.y : 0);
        CGFloat x  = [token parameter:index++] + ([token command] == 's' ? _lastPoint.x : 0);
        CGFloat y  = [token parameter:index++] + ([token command] == 's' ? _lastPoint.y : 0);
        _lastPoint = CGPointMake(x, y);
        CGPathAddCurveToPoint(_path, NULL, x1, y1, x2, y2, x, y);
        _lastControlPoint = CGPointMake(x2, y2);
        _validLastControlPoint = YES;
    }
    if (index == 0) {
        NSLog(@"*** PocketSVG Error: Insufficient parameters for S command");
    }
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
@end
#endif