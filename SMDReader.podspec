Pod::Spec.new do |s|
  s.name     = 'SMDReader'
  s.version  = '0.0.1'
  s.summary  = 'An open source EPUB file reader/viewer for iOS.'
  s.homepage = 'https://github.com/siriusdely/SMDReader'
  s.author   = { 'Sirius Dely' => 'mail@siriusdely.com' }
  s.license  = 'MIT'

  s.source   = { :git => 'https://github.com/siriusdely/SMDReader.git', :commit => 'bc380f50a76c5c998bf7bf1d3ddbd27c54b6af37' }

  s.platform = :ios

  s.source_files = 'SMDReader/Classes/**/*.{h,m,mm}'
  s.requires_arc = true
  s.compiler_flags = '-w' # Disable all warnings

  s.resources = "SMDReader/Resources/*.{xib,png,js,epub}"

  s.dependency 'TouchXML', '0.1'
  s.dependency 'ZipArchive', '1.01h'

end
