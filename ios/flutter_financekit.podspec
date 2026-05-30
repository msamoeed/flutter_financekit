#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_financekit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_financekit'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Apple FinanceKit — accounts, transactions, and balances.'
  s.description      = <<-DESC
A Flutter plugin that wraps the Apple FinanceKit framework (iOS 17.4+), providing
access to financial accounts, account balances, and transactions stored in Apple Wallet.
                       DESC
  s.homepage         = 'https://github.com/example/flutter_financekit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.4'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_SWIFT_FLAGS' => '-DFINANCEKIT_AVAILABLE'
  }
  s.swift_version = '5.9'

  s.frameworks = 'FinanceKit'

  s.resource_bundles = {'flutter_financekit_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
