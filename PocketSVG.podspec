Pod::Spec.new do |s|
  s.name         = "PocketSVG"
  s.version      = "2.0"
  s.summary      = "An Objective-C class that converts Scalable Vector Graphics into Core Graphics elements."
  s.homepage     = "https://github.com/arielelkin/PocketSVG"

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }

  s.authors      = { "Ponderwell, Fjölnir Ásgeirsson, Ariel Elkin, and Contributors" => "https://github.com/arielelkin/PocketSVG" }
  s.source       = { :git => "https://github.com/arielelkin/PocketSVG.git", :tag => s.version }
  s.requires_arc = true
  s.frameworks  = 'QuartzCore'
  s.source_files = 'PocketSVG.{h,m}, 'pathscaler.m', 'SVGBezierPath.{h, mm}', 'SCGImageView.{h,m}', 'SVGLayer.{h,m}', 'SVGPortability.h'
 s.ios.source_files = 'SVGImageView_iOS.h'
 s.osx.source_files = 'SVGImageView_Mac.h'
end
