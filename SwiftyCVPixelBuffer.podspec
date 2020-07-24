Pod::Spec.new do |s|
  s.name = "SwiftyCVPixelBuffer"
  s.version = "0.2.0"

  s.summary = "Swift helpers to make usage of CVPixelBuffer more pleasurable"
  s.homepage = "https://github.com/s1ddok/SwiftyCVPixelBuffer"

  s.author = {
    "Andrey Volodin" => "siddok@gmail.com",
    "Eugene Bokhan" => "eugenebokhan@protonmail.com"
  }
  s.social_media_url = "http://twitter.com/s1ddok"

  s.license = { :type => "MIT", :file => "LICENSE" }

  s.ios.deployment_target = "11.0"
  s.osx.deployment_target = "10.13"

  s.source = {
    :git => "https://github.com/s1ddok/SwiftyCVPixelBuffer.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/**/*.{swift}"

  s.swift_version = "5.2"

  s.frameworks = "CoreVideo"
end
