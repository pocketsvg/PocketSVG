Pod::Spec.new do |s|
  s.name         = "PocketSVG"
  s.version      = "0.7"
  s.summary      = "An Objective-C class that converts Scalable Vector Graphics into Core Graphics elements."
  s.homepage     = "https://github.com/arielelkin/PocketSVG"

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }

  s.authors      = { "Ponderwell, Ariel Elkin, and Contributors" => "https://github.com/arielelkin/PocketSVG" }
  s.source       = { :git => "https://github.com/arielelkin/PocketSVG.git", :tag => s.version }
  s.requires_arc = true
  s.frameworks  = 'QuartzCore'
  s.source_files = 'PocketSVG.{h,m}'
end
