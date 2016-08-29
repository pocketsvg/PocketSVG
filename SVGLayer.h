/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <QuartzCore/QuartzCore.h>

/// An SVG-backed CALayer that you can view that parses, renders, and display an SVG file.

@interface SVGLayer : CALayer
@property(nonatomic, copy) NSString *svgSource;
@property(nonatomic) CGColorRef fillColor, strokeColor;
@property(nonatomic) BOOL scaleLineWidth;

- (void)loadSVGNamed:(NSString *)aName;
@end
