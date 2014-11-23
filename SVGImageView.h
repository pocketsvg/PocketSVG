#import <TargetConditionals.h>

// This setup is just so Interface Builder doesn't get confused.
#if TARGET_OS_IPHONE
#   import "SVGImageView-iOS.h"
#else
#   import "SVGImageView-Mac.h"
#endif
