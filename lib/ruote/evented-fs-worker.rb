require 'rubygems'
require 'bundler/setup'
require 'rufus/cloche'
require 'ruote/storage/fs_storage'

module Ruote
  module EventedFsWorker
    autoload :Base, 'ruote/evented-fs-worker/base'
    autoload :VERSION, 'ruote/evented-fs-worker/version'
    autoload :Cloche, 'ruote/evented-fs-worker/cloche'
    autoload :FsStorage, 'ruote/evented-fs-worker/fs_storage'

    def self.new *args
      Ruote::EventedFsWorker::Base.new *args
    end
  end
end

Rufus::Cloche.send(:include, ::Ruote::EventedFsWorker::Cloche)
Ruote::FsStorage.send(:include, ::Ruote::EventedFsWorker::FsStorage)
