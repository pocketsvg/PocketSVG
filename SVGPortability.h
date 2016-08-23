/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
@compatibility_alias PSVGView UIView;
@compatibility_alias PSVGColor UIColor;
@compatibility_alias PSVGBezierPath UIBezierPath;

#else

#import <AppKit/AppKit.h>
@compatibility_alias PSVGView NSView;
@compatibility_alias PSVGColor NSColor;
@compatibility_alias PSVGBezierPath NSBezierPath;

#endif
