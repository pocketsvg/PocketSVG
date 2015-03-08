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
    CGPathRef myPath = [PocketSVG pathFromSVGFileNamed:@"BezierCurve1"];
    
    //2: To display it on screen, you can create a CAShapeLayer
    //and set myPath as its path property:
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myPath;
    
    
    //3: Fiddle with it using CAShapeLayer's properties:
    myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
    myShapeLayer.lineWidth = 4;
    myShapeLayer.fillColor = [[UIColor clearColor] CGColor];

    //4: Display it!
    [self.view.layer addSublayer:myShapeLayer];


    //Make it smaller if we're on an iPhone:
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        myShapeLayer.transform = CATransform3DMakeScale(0.3, .3, 0.3);
    }
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
