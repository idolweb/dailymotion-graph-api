# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dailymotion-graph-api/version"

Gem::Specification.new do |s|
  s.name        = "dailymotion-graph-api"
  s.version     = DailymotionGraphApi::VERSION
  s.authors     = ["jseveno"]
  s.email       = ["julien.seveno@idol.io"]
  s.homepage    = "https://idol.io"
  s.summary     = "An unofficial gem for using the Dailymotion graph API : http://www.dailymotion.com/doc/api/graph-api.html"
  s.description = "An unofficial gem for using the Dailymotion graph API : http://www.dailymotion.com/doc/api/graph-api.html"
  s.licenses    = ["LGPL"]

  s.rubyforge_project = "dailymotion-graph-api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency "faraday", '~> 0.8', '>= 0.8.6'
  s.add_runtime_dependency "json", '~> 1.8', '>= 1.8.1'

  s.add_development_dependency "bundler", "~> 1.7.11"
  s.add_development_dependency "rake"

  s.requirements << 'faraday, >= 0.8.6'
  s.requirements << 'json'
end
