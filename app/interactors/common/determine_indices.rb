module Common
  class DetermineIndices
    include Interactor

    def call
      idx = []

      context.fail!(error:"Index is required.") if !context.index
      context.fail!(error:"Start is required.") if !context.start
      context.fail!(error:"Finish is required.") if !context.finish

      ts = context.start

      while 1
        idx.push "#{ES_CONFIG.namespace}-#{context.index}-#{ ts.strftime("%Y-%m-%d") }"
        ts += 1.day

        break if ts > context.finish
      end

      context.indices = idx
    end
  end
end