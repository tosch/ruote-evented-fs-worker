# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'ruote/evented-fs-worker/version'

Gem::Specification.new do |s|
  s.name        = "ruote-evented-fs-worker"
  s.version     = Ruote::EventedFsWorker::VERSION
  s.authors     = ["Torsten Schönebaum"]
  s.email       = ["torsten.schoenebaum@googlemail.com"]
  s.homepage    = "https://github.com/tosch/ruote-evented-fs-worker"
  s.summary     = %q{An evented worker for ruote's filesystem storage}
  s.description = %q{ruote is a workflow engine written in Ruby. It supports different storage backend, including the filesystem. This is an alternative worker implementation for ruote which uses EventMachine and a Inotify, thous avoiding polling the filesystem every half second.}

  s.rubyforge_project = "ruote"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'ruote', '>= 2.3.0'
  s.add_dependency 'rb-inotify' # TODO Should be conditional
  s.add_dependency 'eventmachine', '>= 0.12.10'
  s.add_dependency 'em-dir-watcher', '>= 0.9.4'
end
