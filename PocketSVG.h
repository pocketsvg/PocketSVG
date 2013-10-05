//
//  PocketSVG.h
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class PocketSVG;

@protocol PocketSVGDelegate <NSObject>

@optional

-(void)pocketSVGDidFinishParsing:(PocketSVG *)pocket;

@end

@interface PocketSVG : NSObject <NSXMLParserDelegate>{
	@private
	float			pathScale;
#if TARGET_OS_IPHONE
	UIBezierPath    *bezier;
#else
	NSBezierPath    *bezier;
#endif
	CGPoint			lastPoint;
	CGPoint			lastControlPoint;
	BOOL			validLastControlPoint;
	NSCharacterSet  *separatorSet;
	NSCharacterSet  *commandSet;
    
    NSMutableArray  *tokens;
    
    NSMutableArray * paths;
}
#if TARGET_OS_IPHONE
@property(nonatomic, readonly) UIBezierPath *bezier;
#else
@property(nonatomic, readonly) NSBezierPath *bezier;
#endif

@property (strong) NSXMLParser * xmlParser;

@property (weak) id <PocketSVGDelegate> delegate;

- (id)initFromSVGFileNamed:(NSString *)nameOfSVG;

-(id)initWithSVGFileAtURL:(NSURL *)fileURL delegate:(id <PocketSVGDelegate>)svgDel;

#if !TARGET_OS_IPHONE
+ (CGPathRef)getCGPathFromNSBezierPath:(NSBezierPath *)quartzPath;
#endif

@end
