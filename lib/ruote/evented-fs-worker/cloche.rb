module Ruote
  module EventedFsWorker
    module Cloche
      def get_by_path path
        r = lock_path(path) { |f| do_get(f) }

        r == false ? nil : r
      end

      protected

      def lock_path path, &block
        @mutex.synchronize do
          begin
            file = File.new(path, 'r+') rescue nil

            return false if file.nil?

            file.flock(File::LOCK_EX) unless @nolock
            block.call(file)
          ensure
            begin
              file.flock(File::LOCK_UN) unless @nolock
            rescue Exception => e
            end
            begin
              file.close if file
            rescue Exception => e
            end
          end
        end
      end
    end
  end
end
