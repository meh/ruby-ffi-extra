Gem::Specification.new {|s|
    s.name         = 'ffi-extra'
    s.version      = '0.1.0'
    s.author       = 'meh.'
    s.email        = 'meh@paranoici.org'
    s.homepage     = 'http://github.com/meh/ruby-ffi-extra'
    s.platform     = Gem::Platform::RUBY
    s.summary      = 'Some extra methods for FFI'
    s.files        = Dir.glob('lib/**/*.rb')
    s.require_path = 'lib'

    s.add_dependency('ffi')
}
