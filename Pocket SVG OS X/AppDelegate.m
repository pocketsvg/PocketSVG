//
//  AppDelegate.m
//  Pocket SVG OS X
//
//  Created by Ariel on 15/10/2012.
//  Copyright (c) 2012 Ariel. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "PocketSVG.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    //1: Create a PocketSVG object from your SVG file:
    PocketSVG *myVectorDrawing = [[PocketSVG alloc] initFromSVGFileNamed:@"BezierCurve3"];
    
    //2: Its bezier property is the corresponding NSBezierPath:
    NSBezierPath *myBezierPath = myVectorDrawing.bezier;
    
    //3: To display it on screen, create a CAShapeLayer:
    //   and call getCGPathFromNSBezierPath to get the
    //   SVG's CGPath
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = [PocketSVG getCGPathFromNSBezierPath:myBezierPath];
    
    //4: Fiddle with it using CAShapeLayer's properties:
    myShapeLayer.strokeColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1);
    myShapeLayer.lineWidth = 4;
    myShapeLayer.fillColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0);
    
    //5: Display it!
    [self.window.contentView setWantsLayer:YES];
    [self.window.contentView setLayer:myShapeLayer];
    [self.window setFrame:NSRectFromCGRect(CGRectMake(200, 200, 800, 800)) display:YES];
    
    //TODO:
    //The CGPath needs to be displayed in the correct position. Currently 
    
}

@end
