require 'rubygems'

begin
  require 'yajl'
rescue LoadError
  require 'json'
end

require File.expand_path(File.join('..', '..', 'lib', 'ruote', 'evented-fs-worker'), __FILE__)

require 'ruote'
require 'ruote/part/local_participant'

class MessageParticipant
  include Ruote::LocalParticipant

  def on_workitem
    workitem.fields['message'] = { 'text' => 'hello!', 'author' => 'Alice' }

    reply
  end
end

class PutsParticipant
  include Ruote::LocalParticipant

  def on_workitem
    puts "I received a message from #{workitem.fields['message']['author']}"

    reply
  end
end

storage = Ruote::FsStorage.new('ruote_files')
worker = Ruote::EventedFsWorker.new(storage)
dashboard = Ruote::Dashboard.new(worker)

# Participant registration
dashboard.register_participant :alpha, MessageParticipant
dashboard.register_participant :bravo, PutsParticipant

# defining a process
pdef = Ruote.process_definition :name => 'test' do
  sequence do
    participant :alpha
    participant :bravo
  end
end

100.times do
  dashboard.launch(pdef)
end

worker.join

# => 'I received a message from Alice'
