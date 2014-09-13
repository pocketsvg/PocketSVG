Pod::Spec.new do |s|
  s.name         = "PocketSVG"
  s.version      = "0.8"
  s.summary      = "An Objective-C class that converts Scalable Vector Graphics into Core Graphics elements."
  s.homepage     = "https://github.com/ProjectDent/PocketSVG"

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  
  s.authors      = { "Ponderwell, Ariel Elkin, and Contributors" => "https://github.com/arielelkin/PocketSVG" }
  s.source       = { :git => "https://github.com/ProjectDent/PocketSVG.git" }
  s.ios.deployment_target = '5.0'
  s.requires_arc = true
  s.frameworks  = 'QuartzCore'
  s.source_files = 'PocketSVG.{h,m}'
end
