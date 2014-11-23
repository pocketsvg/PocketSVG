#import "SVGViewController.h"
@import SVGPathSerializing;

@implementation SVGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // This can be set using KVC in Interface Builder
    _svgView.svgFileName = @"tiger";
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
