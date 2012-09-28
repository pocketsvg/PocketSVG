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
        
    //1: Create a PocketSVG object from your SVG file:
    PocketSVG *myVectorDrawing = [[PocketSVG alloc] initFromSVGFileNamed:@"BezierCurve1-iPad"];
    
    
    //2: Its bezier property is the corresponding UIBezierPath:
    UIBezierPath *myBezierPath = myVectorDrawing.bezier;
    
    
    //3: To display it on screen, create a CAShapeLayer and set 
    //the CGPath property of the above UIBezierPath as its 
    //path. 
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myBezierPath.CGPath;
    
    
    //4: Fiddle with it using CAShapeLayer's properties:
    myShapeLayer.strokeColor = [[UIColor redColor] CGColor];
    myShapeLayer.lineWidth = 4;
    myShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    
    
    //5: Display it!
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
