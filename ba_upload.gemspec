# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ba_upload/version'

Gem::Specification.new do |spec|
  spec.name          = "ba_upload"
  spec.version       = BaUpload::VERSION
  spec.authors       = ["Stefan Wienert"]
  spec.email         = ["stefan.wienert@pludoni.de"]

  spec.summary       = %q{Upload API for Bundesagentur fuer Arbeit (hrbaxml.arbeitsagentur)}
  spec.description   = %q{Upload API for Bundesagentur fuer Arbeit (hrbaxml.arbeitsagentur)}
  spec.homepage      = "https://github.com/pludoni/ba_upload"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mechanize"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
