//
//  ViewController.m
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


#import "ViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "PocketSVG.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1: Turn your SVG into a CGPath:
    NSString *svg = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BezierCurve1"
                                                                                       ofType:@"svg"]
                                          usedEncoding:NULL
                                                 error:NULL];
    
    NSMapTable *attributes;
    NSArray *paths = PSVGPathsFromSVGString(svg, &attributes);
    NSLog(@"%@", PSVGFromPaths(paths, attributes));

    for(id path in paths) {
        // 2: To display it on screen, you can create a CAShapeLayer:
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = (__bridge CGPathRef)path;
        
        // 3: Apply the path's attributes
        NSDictionary *attrs = [attributes objectForKey:path];
        layer.strokeColor = (__bridge CGColorRef)attrs[@"stroke"]
                          ?:[[UIColor redColor] CGColor];
        layer.lineWidth   = [attrs[@"stroke-width"] floatValue];
        layer.fillColor   = (__bridge CGColorRef)attrs[@"fill"]
                          ?: [[UIColor blueColor] CGColor];
        
        //4: Display it!
        [self.view.layer addSublayer:layer];
    }
    
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
