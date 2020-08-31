# Uncomment the next line to define a global platform for your project
platform :ios, '10.2'
# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!
# ignore all warnings from all pods
inhibit_all_warnings!

def pods
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'FBSDKCoreKit', '~> 4.26'
    pod 'FBSDKLoginKit', '~> 4.26'
    pod 'FBSDKShareKit', '~> 4.26'
    pod 'AccountKit', '~> 4.26'
    pod 'JVFloatLabeledTextField', '~> 1.2'
    pod 'Pulsator', '~> 0.3'
    pod 'Alamofire', '~> 4.3'
    pod 'AlamofireNetworkActivityIndicator', '~> 2.2'
    pod 'AlamofireNetworkActivityLogger', '~> 2.0'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'Gifu', '~> 3.1.0'
    pod 'Kingfisher', '~> 4.0'
    pod 'SZTextView'
    pod 'Toast-Swift', '~> 3.0'
    pod 'Appirater'
    pod 'NextLevel', '~> 0.12'
    pod 'AudioKit', '~> 4.0'
    pod 'SCSiriWaveformView', '~> 1.0'
    pod 'JSONWebToken'
    pod 'PagedArray'
    pod 'SnapKit', '~> 4.0.0'
    pod 'CountdownLabel', '~> 3.0'
    pod 'ImageSlideshow', '~> 1.4'
    pod 'ImageSlideshow/Kingfisher'
    pod 'Firebase/Core'
    pod 'Firebase/Database'
    pod 'MessageKit', '~> 0.3'
    pod 'TwitterKit'
    pod 'DeviceKit', '~> 1.3.0'
    pod 'ACBAVPlayer'
    pod 'RPCircularProgress', '0.4.0'
    pod 'IOStickyHeader'
end


target 'RecordGram' do
    # Pods for RecordGram
    pods
end

target 'RecordGram Staging' do
    # Pods for RecordGram Staging
    pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
    
    # Workaround for Cocoapods issue #7606
    # https://github.com/CocoaPods/CocoaPods/issues/7606#issuecomment-381279098
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
