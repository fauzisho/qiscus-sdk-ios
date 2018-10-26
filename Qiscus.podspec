Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "2.9.0"
s.summary      = "Qiscus SDK for iOS"
s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC
s.homepage     = "https://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/qiscus-sdk-ios.git", :tag => "#{s.version}" }
s.source_files  = "Qiscus/**/*.{swift}"
s.resource_bundles = {
    'Qiscus' => ['Qiscus/**/*.{xcassets,imageset,xib}']
}
s.platform      = :ios, "10.0"
s.dependency 'QiscusCore'
s.dependency 'QiscusUI'
s.dependency 'SDWebImage', '~> 4.0'

end
