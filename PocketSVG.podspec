Pod::Spec.new do |s|
  s.name         = "PocketSVG"
  s.version      = "2.7.3"
  s.summary      = "Easily convert your SVG files into CGPaths, CAShapeLayers, and UIBezierPaths"
  s.homepage     = "https://github.com/pocketsvg/PocketSVG"
  s.authors      = { "Ponderwell, Fjölnir Ásgeirsson, Ariel Elkin, and Contributors" => "https://github.com/pocketsvg/PocketSVG" }
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.13'
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }

  s.source = { :git => "https://github.com/pocketsvg/PocketSVG.git", :tag => s.version }

  s.requires_arc = true
  s.frameworks  = 'QuartzCore'
  s.library   = 'xml2', 'stdc++'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.source_files = ['Sources/', 'Sources/include']
  s.resources = 'Sources/Resources/SVGColors.plist'
  s.osx.exclude_files = 'SVGImageView_iOS.h'
  s.ios.exclude_files = 'SVGImageView_Mac.h'
end
