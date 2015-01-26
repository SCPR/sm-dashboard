module Listening
  class DetermineStartFinish
    include Interactor

    def call
      context.start   = ( context.start ? Time.zone.parse(context.start) : 24.hours.ago ).utc
      context.start   -= context.start.sec
      context.finish  = ( (t = Time.now() - 15) - t.sec ).utc
    end
  end
end