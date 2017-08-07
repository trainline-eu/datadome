# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "datadome/version"

Gem::Specification.new do |spec|
  spec.name          = "datadome"
  spec.version       = Datadome::VERSION
  spec.authors       = ["Maxime Garcia"]
  spec.email         = ["maxime.garcia@shopmium.com"]

  spec.summary       = "Rack middleware for Datadome."
  spec.description   = "Rack middleware for Datadome."
  spec.homepage      = "https://github.com/shopmium/datadome"
  spec.license = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
