#import "SVGViewController.h"
#import "SVGImageView.h"

@implementation SVGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // This can be set using KVC in Interface Builder
    _svgView.svgFileName = @"iceland";
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
