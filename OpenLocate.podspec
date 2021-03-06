Pod::Spec.new do |s|
  s.name         = "OpenLocate"
  s.version      = "0.1.0"
  s.summary      = "OpenLocate is an open source Android and iOS SDK for mobile location collection."
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = "OpenLocate Inc"
  s.homepage     = 'https://github.com/OpenLocate'
  s.source       = { :http => "https://s3-us-west-2.amazonaws.com/openlocate-ios/#{s.version}.zip" }
  
  s.ios.deployment_target = '10.0'
  
  s.source_files = 'Source/*.swift'
  s.framework    = "CoreLocation"
end
