
Pod::Spec.new do |s|
  s.name             = 'XBTextInputView'
  s.version          = '1.1.0'
  s.summary          = '文本输入框'

  s.homepage         = 'https://github.com/LiuSky/XBTextInputView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LiuSky' => '327847390@qq.com' }
  s.source           = { :git => 'https://github.com/LiuSky/XBTextInputView.git', :tag => s.version.to_s }
  s.swift_version         = '5.0'
  s.ios.deployment_target = '9.0'
  s.source_files = 'XBTextInputView/Classes/*'
end
