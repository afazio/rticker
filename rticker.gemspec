
Gem::Specification.new do |s|
  s.name = "rticker"
  s.summary = "Command line-based stock ticker application"
  s.description = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.version = "1.0.2"
  s.author = "Alfred J. Fazio"
  s.email = "alfred.fazio@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.8.7'
  s.files = Dir['**/**']
  s.executables = ['rticker']
  s.has_rdoc = false
end
