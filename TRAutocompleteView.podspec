Pod::Spec.new do |s|
  s.name         = "TRAutocompleteView"
  s.version      = "1.2"
  s.summary      = "Flexible and highly configurable auto complete view, attachable to any UITextField."

  s.homepage     = "https://github.com/TarasRoshko/TRAutocompleteView"
  s.license      = 'FreeBSD'
  s.author       = { "Taras Roshko" => "taras.roshko@gmail.com" }

  s.source       = { :git => "https://github.com/ptliddle/TRAutocompleteView.git", :tag => "v1.2" }
  s.platform     = :ios, '6.0'
  s.source_files = 'src'
  s.requires_arc = true
  
  s.frameworks = 'CoreLocation'
  s.dependencies = { 'AFNetworking' => '~> 2.0', 'BlocksKit' => '~> 2.2.2', 'NSArray+Functional' => '~> 1.0.0' }
end
