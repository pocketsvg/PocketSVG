//
//  ViewController.m
//  PocketSVG
//
//  Created by Ariel Elkin on 02/08/2012.
//  Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license 
//

#import "ViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "SvgToBezier.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the frame in which to draw our SVG:
    CGRect frameRect = CGRectMake(0, 0, 1024, 768);
    
    //Create an SvgToBezier object:
    SvgToBezier *myBezier = [[SvgToBezier alloc] initFromSVGFileNamed:@"BezierCurve3-iPad" rect:frameRect];
        
    UIBezierPath *myPath = myBezier.bezier;
    
    /*CGRect bSize = myPath.bounds;
    float bHeight = bSize.size.height;
    float bWidth = bSize.size.width;
    float bOriginX = bSize.origin.x;
    float bOriginY = bSize.origin.y;
    float widthRatio = 1024/bWidth;
    float heightRatio = 768/bHeight;
    
    NSLog(@"bWidth = %f", bWidth);
    NSLog(@"bHeight = %f", bHeight);
    NSLog(@"xCo = %f", bOriginX);
    NSLog(@"yCo = %f", bOriginY);
    NSLog(@"widthRatio = %f", widthRatio);
    NSLog(@"heightRatio = %f", heightRatio);
    
    
    CGAffineTransform transform1 = CGAffineTransformMakeTranslation(-bOriginX, -bOriginY);
    CGPathRef intermediatePath = CGPathCreateCopyByTransformingPath(myPath.CGPath, &transform1);

    myPath.CGPath = intermediatePath;
    
    
    CGAffineTransform transform2 = CGAffineTransformMakeScale(widthRatio, heightRatio);
    CGPathRef intermediatePath2 = CGPathCreateCopyByTransformingPath(myPath.CGPath, &transform2);
    
    myPath.CGPath = intermediatePath2;
    

    CGRect bSize2 = myPath.bounds;
    float bHeight2 = bSize2.size.height;
    float bWidth2 = bSize2.size.width;
    float bOriginX2 = bSize2.origin.x;
    float bOriginY2 = bSize2.origin.y;
    float widthRatio2 = 1024/bWidth2;
    float heightRatio2 = 768/bHeight2;
    
    NSLog(@"bWidth = %f", bWidth2);
    NSLog(@"bHeight = %f", bHeight2);
    NSLog(@"xCo = %f", bOriginX2);
    NSLog(@"yCo = %f", bOriginY2);
    NSLog(@"widthRatio = %f", widthRatio2);
    NSLog(@"heightRatio = %f", heightRatio2);*/
        
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
