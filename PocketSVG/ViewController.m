//
//  ViewController.m
//  PocketSVG
//
//  Created by Ariel Elkin on 02/08/2012.
//  Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license 
//

#import "ViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "PocketSVG.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the frame in which to draw our SVG:
    CGRect frameRect = CGRectMake(0, 0, 1024, 768);
    
    //Create an SvgToBezier object:
    PocketSVG *myBezier = [[PocketSVG alloc] initFromSVGFileNamed:@"BezierCurve3-iPad" rect:frameRect];
    
    UIBezierPath *myPath = myBezier.bezier;
            
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myPath.CGPath;
    
    myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
    myShapeLayer.lineWidth = 4;
    
    myShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [self.view.layer addSublayer:myShapeLayer];
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
