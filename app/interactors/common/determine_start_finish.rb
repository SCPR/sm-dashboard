module Common
  class DetermineStartFinish
    include Interactor

    LIMIT_OPTS = {
      h:  3600,
      m:  60,
      d:  86400,
    }

    def call
      # FIXME: a couple options:
      # * we have a provided start, and will go start - now
      # * we have a provided start and limit, and will go start - (start + limit)
      # * we have a provided limit, and will go (now - limit) - now
      # * we have nothing: 24.hours.ago - now

      if context.limit
        context.limit =~ /^(\d+)(\w)$/

        if $~
          mult = LIMIT_OPTS[$~[2].to_sym]

          if mult
            context.limit = $~[1].to_i * mult
          else
            raise "Unknown limit parameter: #{$~[1]} || #{$~[2]}"
          end
        else
          raise "Invalid limit parameter"
        end
      end


      if context.start
        context.start   = Time.zone.parse(context.start).utc
      elsif context.limit
        context.start   = (Time.now() - context.limit).utc
      else
        context.start   = 24.hours.ago.utc
      end

      if context.start && context.limit
        context.finish = context.start + context.limit
      else
        context.finish  = (Time.now() - 15).utc
      end

      #binding.pry

      # adjust both back to the start of a period
      context.start   = Time.at( ( context.start.to_i / context.period_length ) * context.period_length ).utc
      context.finish  = Time.at( ( context.finish.to_i / context.period_length ) * context.period_length ).utc
    end
  end
end