# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "photocopier/version"

Gem::Specification.new do |spec|
  spec.name          = "photocopier"
  spec.version       = Photocopier::VERSION
  spec.authors       = ["Stefano Verna", "Ju Liu", "Fabrizio Monti"]
  spec.email         = ["stefano.verna@welaika.com", "ju.liu@welaika.com", "fabrizio.monti@welaika.com"]

  spec.summary       = %q{Photocopier provides FTP/SSH adapters to abstract away file and directory copying.}
  spec.description   = %q{Photocopier provides FTP/SSH adapters to abstract away file and directory copying.}
  spec.homepage      = "https://github.com/welaika/photocopier"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.0"

  spec.add_dependency "activesupport", "~> 4.2.0"
  spec.add_dependency "net-ssh", "~> 2.9.2"
  spec.add_dependency "net-scp", "~> 1.2.1"
  spec.add_dependency "net-ssh-gateway", "~> 1.2.0"

  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "simplecov", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 3.1"
  spec.add_development_dependency "gem-release"
end
