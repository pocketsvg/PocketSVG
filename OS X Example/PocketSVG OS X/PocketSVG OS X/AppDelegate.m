//
//  AppDelegate.m
//  PocketSVG OS X
//
//  Created by Ariel on 29/10/2012.
//  Copyright (c) 2012 Ariel. All rights reserved.
//

#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import "PocketSVG.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //1: Turn your SVG into a CGPath:
    CGPathRef myPath = [PocketSVG pathFromSVGFileNamed:@"BezierCurve1"];
    
    //2: To display it on screen, you can create a CAShapeLayer
    //and set myPath as its path property:
    CAShapeLayer *myShapeLayer = [CAShapeLayer layer];
    myShapeLayer.path = myPath;
    
    //3: Fiddle with it using CAShapeLayer's properties:
    myShapeLayer.strokeColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1);
    myShapeLayer.lineWidth = 4;
    myShapeLayer.fillColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0);
    
    //4: Display it!
    [self.window.contentView setWantsLayer:YES];
    [self.window.contentView setLayer:myShapeLayer];
    [self.window setFrame:NSRectFromCGRect(CGRectMake(200, 200, 800, 800)) display:YES];
    
    //TODO:
    //The CGPath needs to be displayed in the correct position.
}


@end
