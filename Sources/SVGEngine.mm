/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

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
    CF_RETURNS_RETAINED CGPathRef readPolylineTag();
    CF_RETURNS_RETAINED CGPathRef readPolygonTag();
    CF_RETURNS_RETAINED CGPathRef readRectTag();
    CF_RETURNS_RETAINED CGPathRef readCircleTag();
    CF_RETURNS_RETAINED CGPathRef readEllipseTag();
    CF_RETURNS_RETAINED CGPathRef readLineTag();

    NSDictionary *readAttributes();
    float readFloatAttribute(NSString *aName);
    bool hasAttribute(NSString * const aName);
    NSString *readStringAttribute(NSString *aName);
    
private:
    CF_RETURNS_RETAINED CGMutablePathRef _readPolylineTag();
};

struct pathDefinitionParser {
public:
    pathDefinitionParser(NSString *);
    CF_RETURNS_RETAINED CGMutablePathRef parse();

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
    void appendArc();
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
    CGRect _viewBox;
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

    NSUInteger depthWithinUnknownElement = 0;

    while(xmlTextReaderRead(_xmlReader) == 1) {
        int const type = xmlTextReaderNodeType(_xmlReader);
        const char * const tag = (char *)xmlTextReaderConstName(_xmlReader);
        
        CGPathRef path = NULL;
        if(depthWithinUnknownElement > 0) {
            if(type == XML_READER_TYPE_ELEMENT && !xmlTextReaderIsEmptyElement(_xmlReader))
                ++depthWithinUnknownElement;
            else if(type == XML_READER_TYPE_END_ELEMENT)
                --depthWithinUnknownElement;
        } else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "svg") == 0) {
            pushGroup(readAttributes());
        } else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "path") == 0)
            path = readPathTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "polyline") == 0)
            path = readPolylineTag();
        else if (type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "line") == 0)
            path = readLineTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "polygon") == 0)
            path = readPolygonTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "rect") == 0)
            path = readRectTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "circle") == 0)
            path = readCircleTag();
        else if(type == XML_READER_TYPE_ELEMENT && strcasecmp(tag, "ellipse") == 0)
            path = readEllipseTag();
        else if(strcasecmp(tag, "g") == 0 || strcasecmp(tag, "a") == 0) {
            if(type == XML_READER_TYPE_ELEMENT)
                pushGroup(readAttributes());
            else if(type == XML_READER_TYPE_END_ELEMENT)
                popGroup();
        } else if(type == XML_READER_TYPE_ELEMENT && !xmlTextReaderIsEmptyElement(_xmlReader))
            ++depthWithinUnknownElement;
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
              @"Not on a <rect>");

    CGRect const rect = {
        readFloatAttribute(@"x"),     readFloatAttribute(@"y"),
        readFloatAttribute(@"width"), readFloatAttribute(@"height")
    };

    float rx = readFloatAttribute(@"rx");
    float ry = readFloatAttribute(@"ry");
    
    if (!hasAttribute(@"rx")) {
        rx = ry;
    }
    if (!hasAttribute(@"ry")) {
        ry = rx;
    }
    
    CGMutablePathRef rectPath = CGPathCreateMutable();
    CGPathAddRoundedRect(rectPath, NULL, rect, MIN(rx, rect.size.width/2), MIN(ry, rect.size.height/2));
    return rectPath;
}

// Reads <polyline> without validating tag, used for <polygon> also
CF_RETURNS_RETAINED CGMutablePathRef svgParser::_readPolylineTag()
{
    xmlAutoFree char * const pointsDef = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)"points");
    NSScanner *scanner = pointsDef ? [NSScanner scannerWithString:@(pointsDef)] : nil;
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@", "];
    
    double x, y;
    if(![scanner scanDouble:&x] || ![scanner scanDouble:&y]) {
        NSLog(@"*** Error: Too few points in <poly*>");
        return NULL;
    }
    
    NSString * const pathDef = [NSString stringWithFormat:@"M%f,%fL%@",
                                x, y, [scanner.string substringFromIndex:scanner.scanLocation]];

    CGMutablePathRef const path = pathDefinitionParser(pathDef).parse();
    if(!path) {
        NSLog(@"*** Error: Invalid path attribute");
        return NULL;
    } else
        return path;
}
CF_RETURNS_RETAINED CGPathRef svgParser::readPolylineTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "polyline") == 0,
              @"Not on a <polyline>");
    return _readPolylineTag();
}

CF_RETURNS_RETAINED CGPathRef svgParser::readPolygonTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "polygon") == 0,
              @"Not on a <polygon>");
    
    CGMutablePathRef path = _readPolylineTag();
    CGPathCloseSubpath(path);
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
    
    if (!hasAttribute(@"rx")) {
        rx = ry;
    }
    if (!hasAttribute(@"ry")) {
        ry = rx;
    }

    CGMutablePathRef ellipse = CGPathCreateMutable();
    CGPathAddEllipseInRect(ellipse, NULL, CGRectMake(center.x - rx, center.y - ry, rx * 2.0, ry * 2.0));
    return ellipse;
}

CF_RETURNS_RETAINED CGPathRef svgParser::readLineTag()
{
    NSCAssert(strcasecmp((char*)xmlTextReaderConstName(_xmlReader), "line") == 0,
              @"Not on a <line>");
    
    float x1 = readFloatAttribute(@"x1");
    float y1 = readFloatAttribute(@"y1");
    float x2 = readFloatAttribute(@"x2");
    float y2 = readFloatAttribute(@"y2");
    
    CGMutablePathRef line = CGPathCreateMutable();
    CGPathMoveToPoint(line, NULL, x1, y1);
    CGPathAddLineToPoint(line, NULL, x2, y2);
    return line;
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
            NSMutableCharacterSet *skippedChars = [NSCharacterSet.whitespaceAndNewlineCharacterSet mutableCopy];
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
                if([transformCmd isEqualToString:@"matrix"] && transformOperands.size() >= 6) {
                    additionalTransform = CGAffineTransformMake(transformOperands[0], transformOperands[1],
                                                                transformOperands[2], transformOperands[3],
                                                                transformOperands[4], transformOperands[5]);
                } else if([transformCmd isEqualToString:@"rotate"] && transformOperands.size() >= 1) {
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
                } else if([transformCmd isEqualToString:@"translate"] && transformOperands.size() >= 1) {
                    float tx = transformOperands[0];
                    float ty = 0;
                    if (transformOperands.size() >= 2)
                        ty = transformOperands[1];
                    additionalTransform = CGAffineTransformMakeTranslation(tx, ty);
                } else if([transformCmd isEqualToString:@"scale"] && transformOperands.size() >= 1) {
                    float sx = transformOperands[0];
                    float sy = sx;
                    if (transformOperands.size() >= 2)
                        sy = transformOperands[1];
                    additionalTransform = CGAffineTransformMakeScale(sx, sy);
                } else if([transformCmd isEqualToString:@"skewX"] && transformOperands.size() >= 1) {
                    additionalTransform.c = tanf(transformOperands[0] * M_PI / 180.0);
                } else if([transformCmd isEqualToString:@"skewY"] && transformOperands.size() >= 1) {
                    additionalTransform.b = tanf(transformOperands[0] * M_PI / 180.0);
                }

                transform = CGAffineTransformConcat(additionalTransform, transform);
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

bool svgParser::hasAttribute(NSString * const aName)
{
    xmlAutoFree char *value = (char *)xmlTextReaderGetAttribute(_xmlReader, (xmlChar*)[aName UTF8String]);
    return value != NULL;
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

/// This parses a single isolated path. creating a cgpath from just a string formated like the d elemen in a path
CGPathRef CGPathFromSVGPathString(NSString *svgString) {
    CGPathRef const path = pathDefinitionParser(svgString).parse();
    if(!path) {
        NSLog(@"*** Error: Invalid path attribute");
        return NULL;
    } else
        return path;
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
                if (CFGetTypeID((__bridge CFTypeRef)(pathAttrs[key])) == CGColorGetTypeID()) {
                    float const alpha = CGColorGetAlpha((__bridge CGColorRef)pathAttrs[key]);
                    if(alpha < 1.0)
                        [svg appendFormat:@" %@-opacity=\"%.2g\"", key, alpha];
                }
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
    _definition = [aDefinition stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

CF_RETURNS_RETAINED CGMutablePathRef pathDefinitionParser::parse()
{
#ifdef SVG_PATH_SERIALIZER_DEBUG
    NSLog(@"d=%@", attr);
#endif
    _path = CGPathCreateMutable();

    NSScanner * const scanner = [NSScanner scannerWithString:_definition];
    static NSCharacterSet *separators, *commands;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commands   = [NSCharacterSet characterSetWithCharactersInString:kValidSVGCommands];
        separators = [NSMutableCharacterSet characterSetWithCharactersInString:@","];
        [(NSMutableCharacterSet *)separators formUnionWithCharacterSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    });
    scanner.charactersToBeSkipped = separators;

    NSString *cmdBuf;
    while([scanner scanCharactersFromSet:commands intoString:&cmdBuf]) {
        _operands.clear();
        if([cmdBuf length] > 1) {
            scanner.scanLocation -= [cmdBuf length]-1;
        } else {
            while (!scanner.isAtEnd) {
                NSUInteger zeros = 0;
                while ([scanner scanString:@"0" intoString:NULL]) { ++zeros; }
                // Start of a 0.x ?
                if (zeros > 0 && [scanner scanString:@"." intoString:NULL]) {
                    --zeros;
                    scanner.scanLocation -= 2;
                }
                for (NSUInteger i = 0; i < zeros; ++i) { _operands.push_back(0.0); }

                float operand;
                if (![scanner scanFloat:&operand]) {
                    break;
                }
                _operands.push_back(operand);
            }
        }

#ifdef SVG_PATH_SERIALIZER_DEBUG
        NSLog(@"%c %@", opcode, operands);
#endif
        _lastCmd = _cmd;
        _cmd = [cmdBuf characterAtIndex:0];

        if (![cmdBuf.uppercaseString hasPrefix:@"M"] && CGPathIsEmpty(_path)) {
            // Workaround for https://github.com/pocketsvg/PocketSVG/issues/128
            CGPathMoveToPoint(_path, NULL, 0, 0);
        }

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
                appendArc();
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
        CGPoint currentPoint = (_cmd == 'm' && !CGPathIsEmpty(_path))
            ? CGPathGetCurrentPoint(_path)
            : CGPointZero;
        CGFloat x = _operands[i+0] + currentPoint.x;
        CGFloat y = _operands[i+1] + currentPoint.y;

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

static double vectorAngle(double ux, double uy, double vx, double vy)
{
    const double sign = (ux * vy - uy * vx < 0) ? -1 : 1;
    const double umag = sqrt(ux * ux + uy * uy);
    const double vmag = sqrt(ux * ux + uy * uy);
    const double dot = ux * vx + uy * vy;

    double div = dot / (umag * vmag);

    if (div > 1) {
        div = 1;
    }

    if (div < -1) {
        div = -1;
    }

    return sign * acos(div);
}

static CGPoint mapToEllipse(double x, double y, double rx, double ry, double cosphi, double sinphi, double centerx, double centery)
{
    x *= rx;
    y *= ry;

    const double xp = cosphi * x - sinphi * y;
    const double yp = sinphi * x + cosphi * y;

    return CGPointMake((CGFloat)(xp + centerx), (CGFloat)(yp + centery));
}

void pathDefinitionParser::appendArc()
{
    if (_operands.size()%7 != 0) {
        NSLog(@"*** Error: Invalid number of parameters for A command");
        return;
    }
    
    for(NSUInteger offset = 0; offset < _operands.size(); offset += 7) {
        CGPoint const currentPoint = CGPathGetCurrentPoint(_path);
        
        double const px = currentPoint.x;
        double const py = currentPoint.y;
        double rx = _operands[offset];
        double ry = _operands[offset+1];
        double const xAxisRotation = _operands[offset+2];
        double const largeArcFlag = _operands[offset+3];
        double const sweepFlag = _operands[offset+4];
        double const cx = _operands[offset+5] + (_cmd == 'a' ? currentPoint.x : 0);
        double const cy = _operands[offset+6] + (_cmd == 'a' ? currentPoint.y : 0);
        
        const double TAU = M_PI * 2.0;
        
        const double sinphi = sin(xAxisRotation * TAU / 360);
        const double cosphi = cos(xAxisRotation * TAU / 360);
        
        const double pxp = cosphi * (px - cx) / 2 + sinphi * (py - cy) / 2;
        const double pyp = -sinphi * (px - cx) / 2 + cosphi * (py - cy) / 2;
        
        if (pxp == 0 && pyp == 0) {
            return;
        }
        
        rx = abs(rx);
        ry = abs(ry);
        
        const double lambda = (CGFloat) (pow(pxp, 2) / pow(rx, 2) + pow(pyp, 2) / pow(ry, 2));
        
        if (lambda > 1) {
            rx *= sqrt(lambda);
            ry *= sqrt(lambda);
        }
        
        const double rxsq =  pow(rx, 2);
        const double rysq =  pow(ry, 2);
        const double pxpsq =  pow(pxp, 2);
        const double pypsq =  pow(pyp, 2);
        
        double radicant = (rxsq * rysq) - (rxsq * pypsq) - (rysq * pxpsq);
        
        if (radicant < 0) {
            radicant = 0;
        }
        
        radicant /= (rxsq * pypsq) + (rysq * pxpsq);
        radicant = sqrt(radicant) * (largeArcFlag == sweepFlag ? -1 : 1);
        
        const double centerxp = radicant * rx / ry * pyp;
        const double centeryp = radicant * -ry / rx * pxp;
        
        const double centerx = cosphi * centerxp - sinphi * centeryp + (px + cx) / 2;
        const double centery = sinphi * centerxp + cosphi * centeryp + (py + cy) / 2;
        
        const double vx1 = (pxp - centerxp) / rx;
        const double vy1 = (pyp - centeryp) / ry;
        const double vx2 = (-pxp - centerxp) / rx;
        const double vy2 = (-pyp - centeryp) / ry;
        
        double ang1 = vectorAngle(1, 0, vx1, vy1);
        double ang2 = vectorAngle(vx1, vy1, vx2, vy2);
        
        if (sweepFlag == 0 && ang2 > 0) {
            ang2 -= TAU;
        }
        
        if (sweepFlag == 1 && ang2 < 0) {
            ang2 += TAU;
        }
        
        const int segments = (int) MAX(ceil(abs(ang2) / (TAU / 4.0)), 1.0);
        
        ang2 /= segments;
        
        for (int i = 0; i < segments; i++) {
            
            const double a = 4.0 / 3.0 * tan(ang2 / 4.0);
            
            const double x1 = cos(ang1);
            const double y1 = sin(ang1);
            const double x2 = cos(ang1 + ang2);
            const double y2 = sin(ang1 + ang2);
            
            CGPoint p1 = mapToEllipse(x1 - y1 * a, y1 + x1 * a, rx, ry, cosphi, sinphi, centerx, centery);
            CGPoint p2 = mapToEllipse(x2 + y2 * a, y2 - x2 * a, rx, ry, cosphi, sinphi, centerx, centery);
            CGPoint p = mapToEllipse(x2, y2, rx, ry, cosphi, sinphi, centerx, centery);
            
            CGPathAddCurveToPoint(_path, NULL, p1.x, p1.y, p2.x, p2.y, p.x, p.y);
            _lastControlPoint = p2;
            
            ang1 += ang2;
        }
    }
}

hexTriplet::hexTriplet(NSString *str)
{
    static NSDictionary *colorMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef SWIFTPM_MODULE_BUNDLE    
        NSURL *url = [SWIFTPM_MODULE_BUNDLE URLForResource:@"SVGColors" withExtension:@"plist"];
#else
        NSURL *url = [[NSBundle bundleForClass:[SVGAttributeSet class]] URLForResource:@"SVGColors" withExtension:@"plist"];
#endif
        colorMap = [NSDictionary dictionaryWithContentsOfURL:url];
    });
    
    NSString *mapped = colorMap[[str lowercaseString]];
    if (mapped) {
        str = mapped;
    }
    
    if ([str hasPrefix:@"rgb("]) {
		NSCParameterAssert([str hasSuffix:@")"]);
		NSArray<NSString*>* parts = [[str substringWithRange:(NSRange) { 4, str.length-5 }] componentsSeparatedByString:@","];
		NSCParameterAssert([parts count] == 3);
		str = [NSString stringWithFormat:@"#%02x%02x%02x", (unsigned int)parts[0].integerValue, (unsigned int)parts[1].integerValue, (unsigned int)parts[2].integerValue];
	} else {
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
    NSMutableCharacterSet * const separators = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet;
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
- (CGRect) viewBox {
    return _viewBox;
}
@end

@implementation SVGMutableAttributeSet
- (void)setAttributes:(NSDictionary<NSString*,id> *)attributes forPath:(CGPathRef)path
{
    
    if (!_attributes) {
        _attributes = [[NSMapTable alloc] init];
    }
    
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

