require 'ruote/worker'
require 'em-dir-watcher'

module Ruote
  module EventedFsWorker
    class Base < Ruote::Worker
      def initialize(storage)
        raise ArgumentError, 'storage has to be an instance of Ruote::FsStorage' unless storage.kind_of? Ruote::FsStorage

        @subscribers = []

        @storage = storage
        @context = Ruote::Context.new(storage, self)

        @last_time = Time.at(0.0).utc

        @run_thread = nil

        @msgs_dir = File.join(@context.storage.dir, 'msgs')
        @schedules_dir = File.join(@context.storage.dir, 'schedules')

        @msgs_watcher = nil
        @schedules_watcher = nil

        @timers = {}
      end

      # Runs the worker in the current thread. See #run_in_thread for running
      # in a dedicated thread.
      #
      def run
        process_leftovers
        EventMachine.run do
          load_schedules

          @msgs_watcher = EMDirWatcher.watch @msgs_dir do |paths|
            paths.each do |path|
              process_msg_by_path path if File.exists? path
            end
          end

          @schedules_watcher = EMDirWatcher.watch @schedules_dir do |paths|
            paths.each do |path|
              if File.exists? path
                load_schedule_by_path path
              else
                unload_schedule_by_path path
              end
            end
          end
        end
      end

      # Triggers the run method of the worker in a dedicated thread.
      #
      def run_in_thread
        @run_thread = Thread.new { run }
      end

      # Joins the run thread of this worker (if there is no such thread, this
      # method will return immediately, without any effect).
      #
      def join
        @run_thread.join if @run_thread
      end

      # Shuts down this worker (makes sure it won't fetch further messages
      # and schedules).
      #
      def shutdown(join=true)
        EventMachine.stop_event_loop
      end

      protected

      # Processes all msgs which are present
      #
      # We do this before starting the event loop. If we wouldn't do that, those leftovers would
      # never be processed since their files don't change, not giving em-dir-watcher a chance to get
      # them.
      #
      # TODO When starting more than one worker, this is somewhat inconvenient since they all will
      #      try to process those leftovers.
      #
      def process_leftovers
        @context.storage.get_many('msgs').each do |msg|
          process msg
        end
      end

      def process_msg_by_path path
        msg = @context.storage.get_by_path path

        process msg
      end

      def load_schedules
        @context.storage.get_many('schedules').each do |schedule|
          load_schedule schedule
        end
      end

      def load_schedule schedule
        now = Ruote.time_to_utc_s(now)

        if schedule['at'] <= now
          trigger schedule # schedule is overdue, trigger it
        else
          unload_schedule_by_id schedule['_id']

          timeout = Ruote.s_to_at(schedule['at']).utc - Time.now.utc

          @timers[schedule['_id']] = EventMachine::Timer.new(timeout) do
            trigger schedule
          end
        end
      end

      def load_schedule_by_path path
        load_schedule @context.storage.get_by_path path
      end

      def unload_schedule_by_id id
        timer = @timers.delete id
        timer.cancel if timer
      end

      def unload_schedule_by_path path
        unload_schedule_by_id File.basename(path, '.json')
      end
    end
  end
end
