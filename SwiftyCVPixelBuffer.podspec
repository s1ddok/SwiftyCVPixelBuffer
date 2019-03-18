Pod::Spec.new do |s|
  s.name             = 'SwiftyCVPixelBuffer'
  s.version          = '0.1.1'
  s.summary          = 'Swift helpers to make usage of CVPixelBuffer more pleasurable'
  s.homepage         = 'https://github.com/s1ddok/SwiftyCVPixelBuffer'
  s.author           = { 'Andrey Volodin' => 'siddok@gmail.com' }
  s.social_media_url = "http://twitter.com/s1ddok"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.source           = { :git => 'https://github.com/s1ddok/SwiftyCVPixelBuffer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.swift_version = "4.2"
  s.source_files = 'SwiftyCVPixelBuffer/**/*.{swift}'
  s.frameworks = 'CoreVideo'
end
