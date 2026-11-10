/*
 * Ownership regression for #231. Analyze without linking so the public
 * declaration, rather than an inlined implementation, determines ownership.
 */
#import "SVGEngine.h"

void releaseReturnedPath(void)
{
    CGPathRef path = CGPathFromSVGPathString(@"M0 0L10 10");
    if (path)
        CGPathRelease(path);
}

id transferReturnedPathToARC(void)
{
    return CFBridgingRelease(CGPathFromSVGPathString(@"M0 0L10 10"));
}

// This deliberately incorrect caller is a positive control: if the retained
// annotation disappears, the expected leak disappears and -verify fails.
void detectUnreleasedReturnedPath(void)
{
    CGPathRef path = CGPathFromSVGPathString(@"M0 0L10 10");
    (void)path;
} // expected-warning@* {{Potential leak of an object}}
