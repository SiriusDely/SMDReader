Pod::Spec.new do |s|
  s.name     = 'SMDReader'
  s.version  = '0.0.1'
  s.summary  = 'An open source EPUB file reader/viewer for iOS.'
  s.homepage = 'https://github.com/siriusdely/SMDReader'
  s.author   = { 
    'Sirius Dely' => 'mail@siriusdely.com' 
  }
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.source   = {  
    :git => 'https://github.com/siriusdely/SMDReader.git', 
    :commit => '264f029982fdd3edf8d3a4653d50d70078748ee8' 
  }
  s.platform = :ios
  s.source_files = 'SMDReader/Classes/**/*.{h,m}'
  s.requires_arc = true
  s.compiler_flags = '-w' # Disable all warnings
  s.resources = "SMDReader/Resources/*.{png,js}"
  s.dependency 'TouchXML', '0.1'
  s.dependency 'ZipArchive', '1.01h'
end

