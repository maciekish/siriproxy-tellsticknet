# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-tellsticknet"
  s.version     = "0.1" 
  s.authors     = ["maciekish"]
  s.email       = ["m@maciekish.com"]
  s.homepage    = "www.appulize.com"
  s.summary     = %q{A SiriProxy plugin which allows you to control devices connected to Tellstick Live!}
  s.description = %q{This plugin for SiriProxy lets you control devices on your Tellstick Live! account. It requires tdtool.py to be present and anuthenticated}

  s.rubyforge_project = "siriproxy-tellsticknet"

  s.files         = `git ls-files 2> /dev/null`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/* 2> /dev/null`.split("\n")
  s.executables   = `git ls-files -- bin/* 2> /dev/null`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
