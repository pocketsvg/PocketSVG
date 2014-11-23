#import "SVGAppDelegate.h"
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SVGAppDelegate class]));
    }
}

#else
#import <AppKit/AppKit.h>

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}
#endif
