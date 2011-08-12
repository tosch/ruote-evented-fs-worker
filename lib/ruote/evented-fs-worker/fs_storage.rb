module Ruote
  module EventedFsWorker
    module FsStorage
      def get_by_path path
        @cloche.get_by_path path
      end
    end
  end
end
