lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "photocopier/version"

Gem::Specification.new do |spec|
  spec.name          = "photocopier"
  spec.version       = Photocopier::VERSION
  spec.authors       = ["Stefano Verna", "Ju Liu", "Fabrizio Monti"]
  spec.email         = ["stefano.verna@welaika.com", "ju.liu@welaika.com", "fabrizio.monti@welaika.com"]

  spec.summary       = 'Photocopier provides FTP/SSH adapters to abstract away file and directory copying.'
  spec.description   = 'Photocopier provides FTP/SSH adapters to abstract away file and directory copying.'
  spec.homepage      = "https://github.com/welaika/photocopier"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_dependency "activesupport", '~> 5.1', '>= 5.1.1'
  spec.add_dependency "net-scp", "~> 1.2", ">= 1.2.1"
  spec.add_dependency "net-sftp", "~> 2.1.2"
  spec.add_dependency "net-ssh", "~> 4.1"
  spec.add_dependency "net-ssh-gateway", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "pry-byebug", "~> 3.4", '>= 3.4.2'
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "simplecov", "~> 0.14", '>= 0.14.1'
end
