require 'ruote/evented-fs-worker/base'
require 'ruote/evented-fs-worker/version'
require 'ruote/evented-fs-worker/cloche'
require 'ruote/evented-fs-worker/fs_storage'

Rufus::Cloche.send(:include, Ruote::EventedFsWorker::Cloche)
Ruote::FsStorage.send(:include, Ruote::EventedFsWorker::FsStorage)

module Ruote
  module EventedFsWorker
    def self.new *args
      Ruote::EventedFsWorker::Base.new *args
    end
  end
end
