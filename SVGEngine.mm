/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <libxml/xmlreader.h>
#import <vector>

#import "SVGEngine.h"
#import "SVGBezierPath.h"

static void __attribute__((__overloadable__)) _xmlFreePtr(char * const *p) { xmlFree(*p); }
#define xmlAutoFree __attribute__((__cleanup__(_xmlFreePtr)))

NSString * const kValidSVGCommands = @"CcMmLlHhVvZzQqTtAaSs";

struct svgParser {
    svgParser(NSString *);
    NSArray *parse(NSMapTable **aoAttributes);

protected:
    NSString *_source;
    NSMutableArray *_attributeStack;
    xmlTextReaderPtr _xmlReader;

    void pushGroup(NSDictionary *aGroupAttributes);
    void popGroup();

    CF_RETURNS_RETAINED CGPathRef readPathTag();
    CF_RETURNS_RETAINED CGPathRef readPolygonTag();
    CF_RETURNS_RETAINED CGPathRef readRectTag();
    CF_RETURNS_RETAINED CGPathRef readCircleTag();
    CF_RETURNS_RETAINED CGPathRef readEllipseTag();

    NSDictionary *readAttributes();
    float readFloatAttribute(NSString *aName);
    NSString *readStringAttribute(NSString *aName);
};

struct pathDefinitionParser {
public:
    pathDefinitionParser(NSString *);
    CF_RETURNS_RETAINED CGPathRef parse();

protected:
    NSString *_definition;
    CGMutablePathRef _path;
    CGPoint _lastControlPoint;
    unichar _cmd, _lastCmd;
    std::vector<float> _operands;

    void appendMoveTo();
    void appendLineTo();
    void appendCubicCurve();
    void appendShorthandCubicCurve();
    void appendQuadraticCurve();
    void appendShorthandQuadraticCurve();
};

struct hexTriplet {
    hexTriplet(uint32_t bytes);
    hexTriplet(NSString *str);
    hexTriplet(CGColorRef color);

    CGColorRef CGColor();
    NSString *string();

protected:
    uint32_t _data;
};

@interface SVGAttributeSet () {
@public
    NSMapTable *_attributes;
}
@end

static NSMutableDictionary *_SVGParseStyle(NSString *body);
static NSString *_SVGFormatNumber(NSNumber *aNumber);

#pragma mark -

svgParser::svgParser(NSString *aSource)
{
    NSCParameterAssert(aSource);
    _source = aSource;
}

NSArray *svgParser::parse(NSMapTable ** const aoAttributes)
{
    _xmlReader = xmlReaderForDoc((xmlChar *)[_source UTF8String], NULL, NULL, 0);
    NSCAssert(_xmlReader, @"Failed to create XML parser");

    if(aoAttributes)
        *aoAttributes = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory|NSMapTableObjectPointerPersonality
                                              valueOptions:NSMapTableStrongMemory];
    NSMutableArray * const paths = [NSMutableArray new];

    while(xmlTextReaderRead(_xmlReader) == 1) {
        int const type = xmlTextReaderNodeType(_xmlReader);
        const char * const tag = (char *)xmlTextReaderConstName(_xmlReader);
        
        CGPathRef path = NULL;
        if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "path") == 0)
            path = readPathTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "polygon") == 0)
            path = readPolygonTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "rect") == 0)
            path = readRectTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "circle") == 0)
            path = readCircleTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "ellipse") == 0)
            path = readEllipseTag();
        else if(strcasecmp(tag, "g") == 0) {
            if(type == XML_READER_TYPE_ELEMENT)
                pushGroup(readAttributes());
            else if(type == XML_READER_TYPE_END_ELEMENT)
                popGroup();
        }
        if(path) {
            [paths addObject:CFBridgingRelease(path)];
            
            if(aoAttributes) {
                NSDictionary * const attributes = readAttributes();
                if(attributes)
                    [*aoAttributes setObject:attributes forKey:(__bridge id)path];
            }
        }
    }
    xmlFreeTextReader(_xmlReader);
    return paths;
}

void svgParser::pushGroup(NSDictionary *aGroupAttributes)
{
    if(!_attributeStack)
        _attributeStack = [NSMutableArray new];

    [_attributeStack addObject:[_attributeStack.lastObject mutableCopy] ?: [NSMutableDictionary new]];
    if(aGroupAttributes)
        [_attributeStack.lastObject addEntriesFromDictionary:aGroupAttributes];
}
void svgParser::popGroup()
{
    if([_attributeStack count] > 0)
        [_attributeStack removeLastObject];
}

CF_RETURNS_RETAINED CGPathRef svgParser::readPathTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "path") == 0,
              @"Not on a <path>");

    xmlAutoFree char * const pathDef = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)"d");
    if(!pathDef)
        return NULL;

    CGPathRef const path = pathDefinitionParser(@(pathDef)).parse();
    if(!path) {
        NSLog(@"*** Error: Invalid/missing d attribute in <path>");
        return NULL;
    } else
        return path;
}

CF_RETURNS_RETAINED CGPathRef svgParser::readRectTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "rect") == 0,
              @"Not on a <polygon>");

    CGRect const rect = {
        readFloatAttribute(@"x"),     readFloatAttribute(@"y"),
        readFloatAttribute(@"width"), readFloatAttribute(@"height")
    };
    NSString * const pathDefinition = [NSString stringWithFormat:
                                       @"M%@,%@"
                                       @"H%@V%@"
                                       @"H%@V%@Z",
                                       _SVGFormatNumber(@(CGRectGetMinX(rect))),
                                       _SVGFormatNumber(@(CGRectGetMinY(rect))),
                                       _SVGFormatNumber(@(CGRectGetMaxX(rect))),
                                       _SVGFormatNumber(@(CGRectGetMaxY(rect))),
                                       _SVGFormatNumber(@(CGRectGetMinX(rect))),
                                       _SVGFormatNumber(@(CGRectGetMinY(rect)))];

    CGPathRef const path = pathDefinitionParser(pathDefinition).parse();
    if(!path) {
        NSLog(@"*** Error: Invalid path attribute");
        return NULL;
    } else
        return path;
}

CF_RETURNS_RETAINED CGPathRef svgParser::readPolygonTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "polygon") == 0,
              @"Not on a <polygon>");
    
    xmlAutoFree char * const pointsDef  = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)"points");
    NSCharacterSet   * const separators = [NSCharacterSet characterSetWithCharactersInString:@", "];
    NSMutableArray   * const items      = [[@(pointsDef) componentsSeparatedByCharactersInSet:separators] mutableCopy];
    
    if([items count] < 2) {
        NSLog(@"*** Error: Too few points in <polygon>");
        return NULL;
    }
    
    NSString * const x = items[0],
             * const y = items[1];
    [items removeObjectsInRange:(NSRange) { 0, 2 }];
    
    NSString * const pathAttributes = [NSString stringWithFormat:@"M%@,%@L%@Z",
                                                                 x, y, [items componentsJoinedByString:@" "]];

    CGPathRef const path = pathDefinitionParser(pathAttributes).parse();
    if(!path) {
        NSLog(@"*** Error: Invalid path attribute");
        return NULL;
    } else
        return path;
}

CF_RETURNS_RETAINED CGPathRef svgParser::readCircleTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "circle") == 0,
              @"Not on a <circle>");
    CGPoint const center = {
        readFloatAttribute(@"cx"), readFloatAttribute(@"cy")
    };
    float r = readFloatAttribute(@"r");
    CGMutablePathRef circle = CGPathCreateMutable();
    CGPathAddEllipseInRect(circle, NULL, CGRectMake(center.x - r, center.y - r, r * 2.0, r * 2.0));
    return circle;
}

CF_RETURNS_RETAINED CGPathRef svgParser::readEllipseTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "ellipse") == 0,
              @"Not on a <ellipse>");
    CGPoint const center = {
        readFloatAttribute(@"cx"), readFloatAttribute(@"cy")
    };
    float rx = readFloatAttribute(@"rx");
    float ry = readFloatAttribute(@"ry");
    CGMutablePathRef ellipse = CGPathCreateMutable();
    CGPathAddEllipseInRect(ellipse, NULL, CGRectMake(center.x - rx, center.y - ry, rx * 2.0, ry * 2.0));
    return ellipse;
}

NSDictionary *svgParser::readAttributes()
{
    NSMutableDictionary * const attrs = [_attributeStack.lastObject mutableCopy]
                                     ?: [NSMutableDictionary new];
    if(!xmlTextReaderHasAttributes(_xmlReader))
        return attrs;

    xmlTextReaderMoveToFirstAttribute(_xmlReader);
    do {
        const char * const attrName  = (char *)xmlTextReaderConstName(_xmlReader),
                   * const attrValue = (char *)xmlTextReaderConstValue(_xmlReader);

        if(strcasecmp("style", attrName) == 0){
            NSMutableDictionary *style = _SVGParseStyle(@(attrValue));
            // Don't allow overriding of display:none
            if (style[@"display"] && [style[@"display"] caseInsensitiveCompare:@"none"] == NSOrderedSame) {
                [style removeObjectForKey:@"display"];
            }
            [attrs addEntriesFromDictionary:style];
        } else if(strcasecmp("transform", attrName) == 0) {
            // TODO: report syntax errors
            NSScanner * const scanner = [NSScanner scannerWithString:@(attrValue)];
            NSMutableCharacterSet *skippedChars = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
            [skippedChars addCharactersInString:@"(),"];
            scanner.charactersToBeSkipped = skippedChars;

            CGAffineTransform transform = attrs[@"transform"]
                                        ? [attrs[@"transform"] svg_CGAffineTransformValue]
                                        : CGAffineTransformIdentity;
            NSString *transformCmd;
            std::vector<float> transformOperands;
            while([scanner scanUpToString:@"(" intoString:&transformCmd]) {
                transformOperands.clear();
                for(float operand;
                    [scanner scanFloat:&operand];
                    transformOperands.push_back(operand));

                CGAffineTransform additionalTransform = CGAffineTransformIdentity;
                if([transformCmd isEqualToString:@"matrix"])
                    additionalTransform = CGAffineTransformMake(transformOperands[0], transformOperands[1],
                                                                transformOperands[2], transformOperands[3],
                                                                transformOperands[4], transformOperands[5]);
                else if([transformCmd isEqualToString:@"rotate"]) {
                    float const radians = transformOperands[0] * M_PI / 180.0;
                    if (transformOperands.size() == 3) {
                        float const x = transformOperands[1];
                        float const y = transformOperands[2];
                        additionalTransform = CGAffineTransformMake(cosf(radians), sinf(radians),
                                                                    -sinf(radians), cosf(radians),
                                                                    x-x*cosf(radians)+y*sinf(radians), y-x*sinf(radians)-y*cosf(radians));
                    }
                    else {
                        additionalTransform = CGAffineTransformMake(cosf(radians), sinf(radians),
                                                                    -sinf(radians), cosf(radians),
                                                                    0, 0);
                    }
                } else if([transformCmd isEqualToString:@"translate"])
                    additionalTransform = CGAffineTransformMakeTranslation(transformOperands[0], transformOperands[1]);
                else if([transformCmd isEqualToString:@"scale"])
                    additionalTransform = CGAffineTransformMakeScale(transformOperands[0], transformOperands[1]);
                else if([transformCmd isEqualToString:@"skewX"])
                    additionalTransform.c = tanf(transformOperands[0] * M_PI / 180.0);
                else if([transformCmd isEqualToString:@"skewY"])
                    additionalTransform.b = tanf(transformOperands[0] * M_PI / 180.0);

                transform = CGAffineTransformConcat(transform, additionalTransform);
            }
            if(attrs[@"transform"] || !CGAffineTransformEqualToTransform(transform, CGAffineTransformIdentity))
                attrs[@"transform"] = [NSValue svg_valueWithCGAffineTransform:transform];
        } else
            attrs[@(attrName)] = @(attrValue);
    } while(xmlTextReaderMoveToNextAttribute(_xmlReader));
    xmlTextReaderMoveToElement(_xmlReader);

    for(NSString *attr in attrs.allKeys) {
        if([attrs[attr] isKindOfClass:[NSString class]] &&
           ([attr isEqualToString:@"fill"] || [attr isEqualToString:@"stroke"]))
        {
            if([attrs[attr] isEqual:@"none"]) {
                CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
                attrs[attr] = (__bridge_transfer id)CGColorCreate(colorSpace, (CGFloat[]) { 1, 1, 1, 0 });
                CFRelease(colorSpace);
            } else
                attrs[attr] = (__bridge_transfer id)hexTriplet(attrs[attr]).CGColor();
        }
    }

    if(attrs[@"fill"] && attrs[@"fill-opacity"] && [attrs[@"fill-opacity"] floatValue] < 1.0) {
        attrs[@"fill"] = (__bridge_transfer id)CGColorCreateCopyWithAlpha((__bridge CGColorRef)attrs[@"fill"],
                                                                          [attrs[@"fill-opacity"] floatValue]);
        [attrs removeObjectForKey:@"fill-opacity"];
    }
    if(attrs[@"stroke"] && attrs[@"stroke-opacity"] && [attrs[@"stroke-opacity"] floatValue] < 1.0) {
        attrs[@"stroke"] = (__bridge_transfer id)CGColorCreateCopyWithAlpha((__bridge CGColorRef)attrs[@"stroke"],
                                                                            [attrs[@"stroke-opacity"] floatValue]);
        [attrs removeObjectForKey:@"stroke-opacity"];
    }
    return attrs.count > 0 ? attrs : nil;
}

float svgParser::readFloatAttribute(NSString * const aName)
{
    xmlAutoFree char *value = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)[aName UTF8String]);
    return value ? strtof(value, NULL) : 0.0;
}

NSString *svgParser::readStringAttribute(NSString * const aName)
{
    xmlAutoFree char *value = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)[aName UTF8String]);
    return value ? @(value) : nil;
}

NSArray *CGPathsFromSVGString(NSString * const svgString, SVGAttributeSet **outAttributes)
{
    NSMapTable *attributes;
    NSArray *paths = svgParser(svgString).parse(outAttributes ? &attributes : NULL);
    if (outAttributes && (*outAttributes = [SVGAttributeSet new])) {
        (*outAttributes)->_attributes = attributes;
    }
    return paths;
}

NSString *SVGStringFromCGPaths(NSArray * const paths, SVGAttributeSet * const attributes)
{
    CGRect bounds = CGRectZero;
    NSMutableString * const svg = [NSMutableString new];
    for(id path in paths) {
        bounds = CGRectUnion(bounds, CGPathGetBoundingBox((__bridge CGPathRef)path));
        
        [svg appendString:@"  <path"];
        NSDictionary *pathAttrs = [attributes attributesForPath:(__bridge CGPathRef)path];
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
            NSMutableString * const svg_ = (__bridge id)info;
            
            #define FMT(n) _SVGFormatNumber(@(n))
            switch(el->type) {
                case kCGPathElementMoveToPoint:
                    [svg_ appendFormat:@"M%@,%@", FMT(el->points[0].x), FMT(el->points[0].y)];
                    break;
                case kCGPathElementAddLineToPoint:
                    [svg_ appendFormat:@"L%@,%@", FMT(el->points[0].x), FMT(el->points[0].y)];
                    break;
                case kCGPathElementAddQuadCurveToPoint:
                    [svg_ appendFormat:@"Q%@,%@,%@,%@", FMT(el->points[0].x), FMT(el->points[0].y),
                                                        FMT(el->points[1].x), FMT(el->points[1].y)];
                    break;
                case kCGPathElementAddCurveToPoint:
                    [svg_ appendFormat:@"C%@,%@,%@,%@,%@,%@", FMT(el->points[0].x), FMT(el->points[0].y),
                                                              FMT(el->points[1].x), FMT(el->points[1].y),
                                                              FMT(el->points[2].x), FMT(el->points[2].y)];
                    break;
                case kCGPathElementCloseSubpath:
                    [svg_ appendFormat:@"Z"];
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

pathDefinitionParser::pathDefinitionParser(NSString *aDefinition)
{
    _definition = [aDefinition stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

CF_RETURNS_RETAINED CGPathRef pathDefinitionParser::parse()
{
#ifdef SVG_PATH_SERIALIZER_DEBUG
    NSLog(@"d=%@", attr);
#endif
    _path = CGPathCreateMutable();
    CGPathMoveToPoint(_path, NULL, 0, 0);

    NSScanner * const scanner = [NSScanner scannerWithString:_definition];
    static NSCharacterSet *separators, *commands;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commands   = [NSCharacterSet characterSetWithCharactersInString:kValidSVGCommands];
        separators = [NSMutableCharacterSet characterSetWithCharactersInString:@","];
        [(NSMutableCharacterSet *)separators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    });
    scanner.charactersToBeSkipped = separators;

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
                appendCubicCurve();
                break;
            case 'S': case 's':
                appendShorthandCubicCurve();
                break;
            case 'Q': case 'q':
                appendQuadraticCurve();
                break;
            case 'T': case 't':
                appendShorthandQuadraticCurve();
                break;
            case 'A': case 'a':
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
    if(scanner.scanLocation < [_definition length])
        NSLog(@"*** SVG parse error at index: %d: '%c'",
              (int)scanner.scanLocation, [_definition characterAtIndex:scanner.scanLocation]);

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


void pathDefinitionParser::appendCubicCurve()
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

void pathDefinitionParser::appendShorthandCubicCurve()
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


void pathDefinitionParser::appendQuadraticCurve()
{
    if(_operands.size()%4 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for Q command");
        return;
    }
    
    // (x1, y1, x, y)
    for(NSUInteger i = 0; i < _operands.size(); i += 4) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = _operands[i+0] + (_cmd == 'q' ? currentPoint.x : 0);
        CGFloat const y1 = _operands[i+1] + (_cmd == 'q' ? currentPoint.y : 0);
        CGFloat const x  = _operands[i+2] + (_cmd == 'q' ? currentPoint.x : 0);
        CGFloat const y  = _operands[i+3] + (_cmd == 'q' ? currentPoint.y : 0);
        
        CGPathAddQuadCurveToPoint(_path, NULL, x1, y1, x, y);
        _lastControlPoint = CGPointMake(x1, y1);
    }
}

void pathDefinitionParser::appendShorthandQuadraticCurve()
{
    if(_operands.size()%2 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for T command");
        return;
    }
    if(_lastCmd != 'Q' && _lastCmd != 'q' && _lastCmd != 'T' && _lastCmd != 't')
        _lastControlPoint = CGPathGetCurrentPoint(_path);
    
    // (x, y)
    for(NSUInteger i = 0; i < _operands.size(); i += 2) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        CGFloat const x1 = currentPoint.x + (currentPoint.x - _lastControlPoint.x);
        CGFloat const y1 = currentPoint.y + (currentPoint.y - _lastControlPoint.y);
        CGFloat const x  = _operands[i+0] + (_cmd == 't' ? currentPoint.x : 0);
        CGFloat const y  = _operands[i+1] + (_cmd == 't' ? currentPoint.y : 0);

        CGPathAddQuadCurveToPoint(_path, NULL, x1, y1, x, y);
        _lastControlPoint = CGPointMake(x1, y1);
    }
}


hexTriplet::hexTriplet(NSString *str)
{
    NSCParameterAssert([str hasPrefix:@"#"]);
    NSCParameterAssert([str length] == 4 || [str length] == 7);
    if([str length] == 4) {
        str = [str mutableCopy];
        [(NSMutableString *)str insertString:[str substringWithRange:(NSRange) { 3, 1 }]
                                                      atIndex:3];
        [(NSMutableString *)str insertString:[str substringWithRange:(NSRange) { 2, 1 }]
                                                      atIndex:2];
        [(NSMutableString *)str insertString:[str substringWithRange:(NSRange) { 1, 1 }]
                                                      atIndex:1];
    }
    _data = (uint32_t)strtol([str cStringUsingEncoding:NSASCIIStringEncoding]+1, NULL, 16);
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

static NSMutableDictionary *_SVGParseStyle(NSString * const body)
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

static NSString *_SVGFormatNumber(NSNumber * const aNumber)
{
    static NSNumberFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt                       = [NSNumberFormatter new];
        fmt.numberStyle           = NSNumberFormatterDecimalStyle;
        fmt.maximumFractionDigits = 3;
        fmt.decimalSeparator      = @".";
        fmt.minusSign             = @"-";
        fmt.usesGroupingSeparator = NO;
    });
    return [fmt stringFromNumber:aNumber];
}

@implementation SVGAttributeSet
- (NSDictionary<NSString*,id> *)attributesForPath:(CGPathRef)path
{
    return [_attributes objectForKey:(__bridge id)path];
}
- (id)copyWithZone:(NSZone *)zone
{
    SVGMutableAttributeSet *copy = [self.class new];
    if (copy) {
        copy->_attributes = [_attributes copy];
    }
    return copy;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
    SVGMutableAttributeSet *copy = [SVGMutableAttributeSet new];
    if (copy) {
        copy->_attributes = [_attributes copy];
    }
    return copy;
}
@end

@implementation SVGMutableAttributeSet
- (void)setAttributes:(NSDictionary<NSString*,id> *)attributes forPath:(CGPathRef)path
{
    [_attributes setObject:attributes forKey:(__bridge id)path];
}
@end

#pragma mark -

@implementation NSValue (PocketSVG)
+ (instancetype)svg_valueWithCGAffineTransform:(CGAffineTransform)aTransform
{
#if TARGET_OS_IPHONE
    return [self valueWithCGAffineTransform:aTransform];
#else
    return [self valueWithBytes:&aTransform objCType:@encode(CGAffineTransform)];
#endif
}

- (CGAffineTransform)svg_CGAffineTransformValue
{
#if TARGET_OS_IPHONE
    return [self CGAffineTransformValue];
#else
    if(strcmp(self.objCType, @encode(CGAffineTransform)) == 0) {
        CGAffineTransform transform;
        [self getValue:&transform];
        return transform;
    } else
        return (CGAffineTransform) {0};
#endif
}
@end
