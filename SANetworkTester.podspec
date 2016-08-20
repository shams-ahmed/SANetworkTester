Pod::Spec.new do |s|
  s.name             = "SANetworkTester"
  s.version          = "0.4.0"
  s.summary          = "Quick and Easy way to check for active network connection using Blocks or Delegate"
  s.description      = <<-DESC
                      Test network using ping test such as Google DNS(8.8.8.8), Apple or any IP Address of your choice. Built on top of key Apple frameworks, Support ARC and iOS 6/7+
                       DESC
  s.homepage         = "https://github.com/shams-ahmed/SANetworkTester"
  s.license          = 'MIT'
  s.author           = { "shams-ahmed" => "Shams Ahmed" }
  s.source           = { :git => "https://github.com/shams-ahmed/SANetworkTester.git", :tag => s.version.to_s }
  s.platform         = :ios, '6.0'
  s.requires_arc     = true
  s.source_files = 'Classes/Source'
  s.frameworks = 'CFNetwork', 'MobileCoreServices', 'SystemConfiguration'
end
