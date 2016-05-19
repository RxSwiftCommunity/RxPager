Pod::Spec.new do |s|
s.name             = "RxPager"
s.version          = "0.1.0"
s.summary          = "A simple Pager class fo Rx."
s.homepage         = "https://github.com/pgherveou/RxPager"
s.license          = 'MIT'
s.author           = { "Pierre-Guillaume Herveou" => "pgherveou@gmail.com" }
s.source           = { :git => "https://github.com/pgherveou/RxPager.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/pgherveou'
s.ios.deployment_target = '8.0'
s.source_files = 'RxPager/Classes/**/*'
s.dependency 'RxSwift', '~> 2.5.0'
end
