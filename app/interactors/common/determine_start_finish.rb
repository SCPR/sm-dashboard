module Common
  class DetermineStartFinish
    include Interactor

    def call
      # FIXME: a couple options:
      # * we have a provided start, and will go start - now
      # * we have a provided start and limit, and will go start - (start + limit)
      # * we have a provided limit, and will go (now - limit) - now
      # * we have nothing: 24.hours.ago - now

      context.start   = ( context.start ? Time.zone.parse(context.start) : 24.hours.ago ).utc
      context.finish  = (Time.now() - 15).utc

      # adjust both back to the start of a period
      context.start   = Time.at( ( context.start.to_i / context.period_length ) * context.period_length ).utc
      context.finish  = Time.at( ( context.finish.to_i / context.period_length ) * context.period_length ).utc
    end
  end
end