//
//  PocketSVG.m
//
//  Based on SvgToBezier.m, created by by Martin Haywood on 5/9/11.
//  Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license 2011 Ponderwell.
//
//  NB: Private methods here declared in a class extension, implemented in the class' main implementation block.
//
//  Cleaned up by Bob Monaghan - Glue Tools LLC 6 November 2011
//  Integrated into PocketSVG 10 August 2012
//

#import "PocketSVG.h"

NSInteger const maxPathComplexity	= 1000;
NSInteger const maxParameters		= 64;
NSInteger const maxTokenLength		= 64;
NSString* const separatorCharString = @"-,CcMmLlHhVvZzqQaAsS";
NSString* const commandCharString	= @"CcMmLlHhVvZzqQaAsS";
unichar const invalidCommand		= '*';



@interface Token : NSObject {
	@private
	unichar			command;
	NSMutableArray  *values;
}

- (id)initWithCommand:(unichar)commandChar;
- (void)addValue:(CGFloat)value;
- (CGFloat)parameter:(NSInteger)index;
- (NSInteger)valence;
@property(nonatomic, assign) unichar command;
@end


@implementation Token

- (id)initWithCommand:(unichar)commandChar {
	self = [self init];
    if (self) {
		command = commandChar;
		values = [[NSMutableArray alloc] initWithCapacity:maxParameters];
	}
	return self;
}

- (void)addValue:(CGFloat)value {
	[values addObject:[NSNumber numberWithDouble:value]];
}

- (CGFloat)parameter:(NSInteger)index {
	return [[values objectAtIndex:index] doubleValue];
}

- (NSInteger)valence
{
	return [values count];
}


@synthesize command;

@end


@interface PocketSVG ()

- (NSMutableArray *)parsePath:(NSString *)attr;
- (UIBezierPath *) generateBezier:(NSArray *)tokens;

- (void)reset;
- (void)appendSVGMCommand:(Token *)token;
- (void)appendSVGLCommand:(Token *)token;
- (void)appendSVGCCommand:(Token *)token;
- (void)appendSVGSCommand:(Token *)token;
- (CGPoint)bezierPoint:(CGPoint)svgPoint;

@end


@implementation PocketSVG

@synthesize bezier;


- (id)initFromSVGFileNamed:(NSString *)nameOfSVG rect:(CGRect)rect{
    return [self initFromSVGPathNodeDAttr:[self parseSVGNamed:nameOfSVG] rect:rect];
}

/********
 Returns the content of the SVG's d attribute as an NSString
*/
-(NSString *)parseSVGNamed:(NSString *)nameOfSVG{
    
    NSString *pathOfSVGFile = [[NSBundle mainBundle] pathForResource:nameOfSVG ofType:@"svg"];
    
    if(pathOfSVGFile == nil){
        NSLog(@"*** PocketSVG Error: No SVG file named \"%@\".", nameOfSVG);
        return nil;
    }
    
    NSError *error = nil;
    NSString *mySVGString = [[NSString alloc] initWithContentsOfFile:pathOfSVGFile encoding:NSStringEncodingConversionExternalRepresentation error:&error];
    
    if(error != nil){
        NSLog(@"*** PocketSVG Error: Couldn't read contents of SVG file named %@:", nameOfSVG);
        NSLog(@"%@", error);
        return nil;
    }
    
    //Uncomment the two lines below to print the raw data of the SVG file:
    //NSLog(@"*** PocketSVG: Raw SVG data of %@:", nameOfSVG);
    //NSLog(@"%@", mySVGString);
    
    mySVGString = [mySVGString stringByReplacingOccurrencesOfString:@"id=" withString:@""];
    
    NSArray *components = [mySVGString componentsSeparatedByString:@"d="];
    
    if([components count] < 2){
        NSLog(@"*** PocketSVG Error: No d attribute found in SVG file.");
        return nil;
    }
    
    NSString *dString = [components lastObject];
    dString = [dString substringFromIndex:1];
    NSRange d = [dString rangeOfString:@"\""];    
    dString = [dString substringToIndex:d.location];
    
    dString = [dString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //Uncomment the line below to print the raw path data of the SVG file:
    //NSLog(@"*** PocketSVG: Path data of %@ is: %@", nameOfSVG, dString);
    
    return dString;
    
}


- (id)initFromSVGPathNodeDAttr:(NSString *)attr rect:(CGRect)rect
{
	self = [super init];
	if (self) {
		pathScale = 0;
		viewBox = rect;
		[self reset];
		separatorSet = [NSCharacterSet characterSetWithCharactersInString:separatorCharString];
		commandSet = [NSCharacterSet characterSetWithCharactersInString:commandCharString];
		tokens = [self parsePath:attr];
		bezier = [self generateBezier:tokens];
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
	NSMutableArray *stringTokens = [NSMutableArray arrayWithCapacity: maxPathComplexity];
	
	NSInteger index = 0;
	while (index < [attr length]) {
		NSMutableString *stringToken = [[NSMutableString alloc] initWithCapacity:maxTokenLength];
		[stringToken setString:@""];
		unichar	charAtIndex = [attr characterAtIndex:index];
		if (charAtIndex != ',') {
			[stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
		}
		if (![commandSet characterIsMember:charAtIndex] && charAtIndex != ',') {
			while ( (++index < [attr length]) && ![separatorSet characterIsMember:(charAtIndex = [attr characterAtIndex:index])] ) {
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
	tokens = [[NSMutableArray alloc] initWithCapacity:maxPathComplexity];
	index = 0;
	NSString *stringToken = [stringTokens objectAtIndex:index];
	unichar command = [stringToken characterAtIndex:0];
	while (index < [stringTokens count]) {
		if (![commandSet characterIsMember:command]) {
			NSLog(@"*** PocketSVG Error: Path string parse error: found float where expecting command at token %d in path %s.", 
					index, [attr cStringUsingEncoding:NSUTF8StringEncoding]);
			return nil;
		}
		Token *token = [[Token alloc] initWithCommand:command];
		
		// There can be any number of floats after a command. Suck them in until the next command.
		while ((++index < [stringTokens count]) && ![commandSet characterIsMember:
				(command = [(stringToken = [stringTokens objectAtIndex:index]) characterAtIndex:0])]) {
			
			NSScanner *floatScanner = [NSScanner scannerWithString:stringToken];
			float value;
			if (![floatScanner scanFloat:&value]) {
				NSLog(@"*** PocketSVG Error: Path string parse error: expected float or command at token %d (but found %s) in path %s.", 
					  index, [stringToken cStringUsingEncoding:NSUTF8StringEncoding], [attr cStringUsingEncoding:NSUTF8StringEncoding]);
				return nil;
			}
			// Maintain scale.
			pathScale = (abs(value) > pathScale) ? abs(value) : pathScale;
			[token addValue:value];
		}
		
		// now we've reached a command or the end of the stringTokens array
		[tokens	addObject:token];
	}
	//[stringTokens release];
	return tokens;
}

- (UIBezierPath *)generateBezier:(NSArray *)inTokens
{
	bezier = [[UIBezierPath alloc] init];
	[self reset];
	for (Token *thisToken in inTokens) {
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
				[bezier closePath];
				break;
			default:
				NSLog(@"*** PocketSVG Error: Cannot process command : '%c'", command);
				break;
		}
	}
	return bezier;
}

- (void)reset
{
	lastPoint = CGPointMake(0, 0);
	validLastControlPoint = NO;
}

- (CGPoint)bezierPoint:(CGPoint)svgPoint
{
	/*CGPoint newPoint;
    
 	CGFloat scaleX = viewBox.size.width / pathScale;
	CGFloat scaleY = viewBox.size.height / pathScale;

    newPoint.x = (svgPoint.x * scaleX) + viewBox.origin.x;
    newPoint.y = (svgPoint.y * scaleY) + viewBox.origin.y;*/
	return svgPoint;
    
}

- (void)appendSVGMCommand:(Token *)token
{
	validLastControlPoint = NO;
	NSInteger index = 0;
	BOOL first = YES;
	while (index < [token valence]) {
		CGFloat x = [token parameter:index] + ([token command] == 'm' ? lastPoint.x : 0);
		if (++index == [token valence]) {
			NSLog(@"*** PocketSVG Error: Invalid parameter count in M style token");
			return;
		}
		CGFloat y = [token parameter:index] + ([token command] == 'm' ? lastPoint.y : 0);
		lastPoint = CGPointMake(x, y);
		if (first) {
			[bezier moveToPoint:[self bezierPoint:lastPoint]];
			first = NO;
		}
		else {
#ifdef TARGET_OS_IPHONE
			[bezier addLineToPoint:[self bezierPoint:lastPoint]];
#else
			[bezier lineToPoint:NSPointFromCGPoint([self bezierPoint:lastPoint])];
#endif
		}
		index++;
	}
}

- (void)appendSVGLCommand:(Token *)token
{
	validLastControlPoint = NO;
	NSInteger index = 0;
	while (index < [token valence]) {
		CGFloat x = 0;
		CGFloat y = 0;
		switch ( [token command] ) {
			case 'l':
				x = lastPoint.x;
				y = lastPoint.y;
			case 'L':
				x += [token parameter:index];
				if (++index == [token valence]) {
					NSLog(@"*** PocketSVG Error: Invalid parameter count in L style token");
					return;
				}
				y += [token parameter:index];
				break;
			case 'h' :
				x = lastPoint.x;				
			case 'H' :
				x += [token parameter:index];
				y = lastPoint.y;
				break;
			case 'v' :
				y = lastPoint.y;
			case 'V' :
				y += [token parameter:index];
				x = lastPoint.x;
				break;
			default:
				NSLog(@"*** PocketSVG Error: Unrecognised L style command.");
				return;
		}
		lastPoint = CGPointMake(x, y);
#ifdef TARGET_OS_IPHONE
		[bezier addLineToPoint: [self bezierPoint: lastPoint]];
#else
		[bezier lineToPoint:NSPointFromCGPoint([self bezierPoint: lastPoint])];
#endif
		index++;
	}
}

- (void)appendSVGCCommand:(Token *)token
{
	NSInteger index = 0;
	while ((index + 5) < [token valence]) {  // we must have 6 floats here (x1, y1, x2, y2, x, y).
		CGFloat x1 = [token parameter:index++] + ([token command] == 'c' ? lastPoint.x : 0);
		CGFloat y1 = [token parameter:index++] + ([token command] == 'c' ? lastPoint.y : 0);
		CGFloat x2 = [token parameter:index++] + ([token command] == 'c' ? lastPoint.x : 0);
		CGFloat y2 = [token parameter:index++] + ([token command] == 'c' ? lastPoint.y : 0);
		CGFloat x  = [token parameter:index++] + ([token command] == 'c' ? lastPoint.x : 0);
		CGFloat y  = [token parameter:index++] + ([token command] == 'c' ? lastPoint.y : 0);
		lastPoint = CGPointMake(x, y);
#ifdef TARGET_OS_IPHONE
		[bezier addCurveToPoint:[self bezierPoint:lastPoint] 
				  controlPoint1:[self bezierPoint:CGPointMake(x1,y1)] 
				  controlPoint2:[self bezierPoint:CGPointMake(x2, y2)]];
#else
		[bezier curveToPoint:NSPointFromCGPoint([self bezierPoint:lastPoint])
			   controlPoint1:NSPointFromCGPoint([self bezierPoint:CGPointMake(x1,y1)])
			   controlPoint2:NSPointFromCGPoint([self bezierPoint:CGPointMake(x2, y2)])];
#endif
        lastControlPoint = CGPointMake(x2, y2);
		validLastControlPoint = YES;
	}
	if (index == 0) {
		NSLog(@"*** PocketSVG Error: Insufficient parameters for C command");
	}
}

- (void)appendSVGSCommand:(Token *)token
{
	if (!validLastControlPoint) {
		NSLog(@"*** PocketSVG Error: Invalid last control point in S command");
	}
	NSInteger index = 0;
	while ((index + 3) < [token valence]) {  // we must have 4 floats here (x2, y2, x, y).
		CGFloat x1 = lastPoint.x + (lastPoint.x - lastControlPoint.x); // + ([token command] == 's' ? lastPoint.x : 0);
		CGFloat y1 = lastPoint.y + (lastPoint.y - lastControlPoint.y); // + ([token command] == 's' ? lastPoint.y : 0);
		CGFloat x2 = [token parameter:index++] + ([token command] == 's' ? lastPoint.x : 0);
		CGFloat y2 = [token parameter:index++] + ([token command] == 's' ? lastPoint.y : 0);
		CGFloat x  = [token parameter:index++] + ([token command] == 's' ? lastPoint.x : 0);
		CGFloat y  = [token parameter:index++] + ([token command] == 's' ? lastPoint.y : 0);
		lastPoint = CGPointMake(x, y);
#ifdef TARGET_OS_IPHONE
		[bezier addCurveToPoint:[self bezierPoint:lastPoint] 
				  controlPoint1:[self bezierPoint:CGPointMake(x1,y1)]
				  controlPoint2:[self bezierPoint:CGPointMake(x2, y2)]];
#else
		[bezier curveToPoint:NSPointFromCGPoint([self bezierPoint:lastPoint])
			   controlPoint1:NSPointFromCGPoint([self bezierPoint:CGPointMake(x1,y1)]) 
			   controlPoint2:NSPointFromCGPoint([self bezierPoint:CGPointMake(x2, y2)])];
#endif
		lastControlPoint = CGPointMake(x2, y2);
		validLastControlPoint = YES;
	}
	if (index == 0) {
		NSLog(@"*** PocketSVG Error: Insufficient parameters for S command");
	}
}

@end
