# -*- encoding: utf-8 -*-
require File.expand_path('../lib/photocopier/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Stefano Verna", "Ju Liu"]
  gem.email         = ["stefano.verna@welaika.com", "ju.liu@welaika.com"]
  gem.description   = %q{Photocopier provides FTP/SSH adapters to abstract away file and directory copying.}
  gem.summary       = %q{Photocopier provides FTP/SSH adapters to abstract away file and directory copying.}
  gem.homepage      = "https://github.com/welaika/photocopier"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^exe/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "photocopier"
  gem.require_paths = ["lib"]
  gem.version       = Photocopier::VERSION

  gem.required_ruby_version = ">= 2.1.2"

  gem.add_dependency "activesupport"
  gem.add_dependency "i18n"
  gem.add_dependency "net-ssh"
  gem.add_dependency "net-scp"
  gem.add_dependency "net-ssh-gateway"
  gem.add_dependency "escape"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.2"
  gem.add_development_dependency "pry-byebug"
end
