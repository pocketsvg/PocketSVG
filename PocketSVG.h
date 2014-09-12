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

#import <UIKit/UIKit.h>

@interface PocketSVG : NSObject {
	@private
	float			pathScale;
	UIBezierPath    *bezier;
	CGPoint			lastPoint;
	CGPoint			lastControlPoint;
	BOOL			validLastControlPoint;
	NSCharacterSet  *separatorSet;
	NSCharacterSet  *commandSet;
    
    NSMutableArray  *tokens;
}

@property(nonatomic, readonly) UIBezierPath *bezier;

- (id)initWithSVGFileNamed:(NSString *)nameOfSVG;
- (id)initWithSVGFileAtURL:(NSURL *)svgFileURL;
- (id)initWithSVGString:(NSString *)svgString;
- (id)initWithDAttribute:(NSString *)dAttribute;

/*!
 *  Returns a CGPathRef corresponding to the path represented by a local SVG file's d attribute.
 *
 *  @param nameOfSVG The name of the SVG file. The methods looks for a SVG with the specified in the application's main bundle.
 *
 *  @param scale The scale at which to draw the SVG file.
 *
 *  @param borderPadding Additional space required surrounding the path once scaled, possibly for a border.
 *
 *  @return A CGPathRef object for the SVG in the specified file, or nil if the object could not be found or could not be parsed.
 */
+ (CGPathRef)pathFromSVGFileNamed:(NSString *)nameOfSVG scale:(float)scale borderPadding:(float)borderPadding;

/*!
 *  Returns a CGPathRef corresponding to the path represented by a local SVG file's D attribute
 *
 *  @param svgFileURL The URL to the file.
 *
 *  @return A CGPathRef object for the SVG in the specified file, or nil if the object could not be found or could not be parsed.
 */
+ (CGPathRef)pathFromSVGFileAtURL:(NSURL *)svgFileURL;

/*!
 *  Returns a CGPathRef corresponding to the path represented by a string with SVG formatted contents.
 *
 *  @param svgString The string containing the SVG formatted path.
 *
 *  @return A CGPathRef object for the SVG in the string, or nil if no path is found or the string could not be parsed.
 */
+ (CGPathRef)pathFromSVGString:(NSString *)svgString;

/*!
 *  Returns a CGPathRef corresponding to the path represented by a string with the contents of the d attribute of a path node in an SVG file.
 *
 *  @param dAttribute The string containing the d attribute with the path.
 *
 *  @return A CGPathRef object for the path in the string, or nil if no path is found or the string could not be parsed.
 */
+ (CGPathRef)pathFromDAttribute:(NSString *)dAttribute;



@end
