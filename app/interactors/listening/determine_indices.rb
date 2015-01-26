module Listening
  class DetermineIndices
    include Interactor

    def call
      idx = []

      ts = context.start

      while 1
        idx.push "#{ES_CONFIG.namespace}-listens-#{ ts.strftime("%Y-%m-%d") }"
        ts += 1.day

        break if ts > context.finish
      end

      context.indices = idx
    end
  end
end