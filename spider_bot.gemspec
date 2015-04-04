# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spider_bot/version'

Gem::Specification.new do |spec|
  spec.name          = "spider_bot"
  spec.version       = SpiderBot::VERSION
  spec.authors       = ["yee.li"]
  spec.email         = ["yeeli@outlook.com"]
  spec.summary       = %q{splider bot}
  spec.description   = %q{splider bot}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "active_support"

  spec.add_dependency "faraday"
  spec.add_dependency "nokogiri"
  spec.add_dependency "multi_json"
  spec.add_dependency "multi_xml"
  spec.add_dependency "tzinfo"
  spec.add_dependency "thor"
  spec.add_dependency 'daemons'
end
