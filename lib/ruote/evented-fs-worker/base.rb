require 'ruote/worker'
require 'eventmachine'
require 'em-dir-watcher'
require 'fileutils'

module Ruote
  module EventedFsWorker
    class Base < Ruote::Worker
      def initialize(name, storage = nil)
        super(name, storage)

        raise ArgumentError, 'storage has to be an instance of Ruote::FsStorage' unless @storage.kind_of? Ruote::FsStorage

        @msgs_dir = File.join(@context.storage.dir, 'msgs')
        @schedules_dir = File.join(@context.storage.dir, 'schedules')

        @msgs_dir_watcher = nil
        @schedules_dir_watcher = nil

        @timers = {}
      end

      # Runs the worker in the current thread. See #run_in_thread for running
      # in a dedicated thread.
      #
      def run
        FileUtils.mkdir_p(@msgs_dir) unless File.exists?(@msgs_dir)
        FileUtils.mkdir_p(@schedules_dir) unless File.exists?(@schedules_dir)

        EventMachine.run do
          load_schedules

          msgs_dir_watcher

          #puts "Watching msgs dir"

          schedules_dir_watcher

          #puts "Watching schedules dir"

          process_leftovers
        end

        #puts "EM core stopped"
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
        #puts "Processing leftovers"

        @context.storage.get_many('msgs').each do |msg|
          #puts "Processing #{msg.inspect}"

          process msg
        end

        #puts "Finished processing leftovers"
      end

      def process_msg_by_path(path)
        process(@context.storage.get_by_path(path))
      end

      def load_schedules
        #puts "Loading schedules"

        @context.storage.get_many('schedules').each do |schedule|
          load_schedule(schedule)
        end

        #puts "Finished loading schedules"
      end

      def load_schedule(schedule)
        #puts "Loading schedule #{schedule.inspect}"

        now = Ruote.time_to_utc_s(now)

        if schedule['at'] <= now
          trigger(schedule) # schedule is overdue, trigger it
        else
          unload_schedule_by_id(schedule['_id'])

          timeout = Ruote.s_to_at(schedule['at']).utc - Time.now.utc

          @timers[schedule['_id']] = EventMachine::Timer.new(timeout) do
            trigger(schedule)
          end
        end

        #puts "Finished loading schedule"
      end

      def load_schedule_by_path(path)
        load_schedule(@context.storage.get_by_path path)
      end

      def unload_schedule_by_id(id)
        timer = @timers.delete(id)
        timer.cancel if timer
      end

      def unload_schedule_by_path(path)
        unload_schedule_by_id(File.basename(path, '.json'))
      end

      def msgs_dir_watcher
        return @msgs_dir_watcher if @msgs_dir_watcher

        return nil unless File.exists?(@msgs_dir)

        #puts "Trying to set watcher on #{@msgs_dir}"

        @msgs_dir_watcher = EMDirWatcher.watch(@msgs_dir) do |paths|
          #puts paths.inspect

          paths.each do |path|
            #puts "MSG: Change in #{path}"

            process_msg_by_path(File.join(@msgs_dir, path)) if File.exists?(path)
          end

          schedules_dir_watcher
        end
      end

      def schedules_dir_watcher
        return @schedules_dir_watcher if @schedules_dir_watcher

        return nil unless File.exists?(@schedules_dir)

        #puts "Trying to set watcher on #{@schedules_dir}"

        @schedules_dir_watcher = EMDirWatcher.watch(@schedules_dir) do |paths|
          paths.each do |path|
            #puts "SCHED: Change in #{path}"

            if File.exists?(path)
              load_schedule_by_path(File.join(@schedules_dir, path))
            else
              unload_schedule_by_path(File.join(@schedules_dir, path))
            end
          end
        end
      end
    end
  end
end
