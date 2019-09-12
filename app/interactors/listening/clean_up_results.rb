module Listening
  class CleanUpResults
    include Interactor

    def call
      return unless context._results.aggregations
      if context._results.aggregations && context._results.aggregations.periods?
        clean = []
        context._results.aggregations.periods.buckets.each do |b|
          ts = Time.at(b['key'] / 1000)
          obj = self._clean(b,Hashie::Mash.new({time:ts.utc}))
          clean << obj
        end

        context.results = clean
      elsif context._results.aggregations && context._results.aggregations.schedule?
        clean = []
        context._results.aggregations.schedule.buckets.each_with_index do |b,i|
          obj = self._clean(b,Hashie::Mash.new(context.schedule[i]))
          clean << obj
        end

        context.results = clean
      else
        context.results = self._clean(context._results.aggregations,Hashie::Mash.new())
      end
    end

    #----------

    def _clean(b,obj)
      if b.sessions?
        obj.sessions  = b.sessions.value
      end

      if b.cume?
        obj.cume      = b.cume.value
      end

      if b.duration?
        obj.duration  = b.duration.value

        if obj._duration
          obj.listeners = ( b.duration.value / obj._duration ).round()
        else
          obj.listeners = ( b.duration.value / context.period_length ).round()
        end
      end

      if b.avg_duration?
        obj.avg_duration = b.avg_duration.values[0]['50.0']
      end

      if b.starts?
        obj.starts    = b.starts.buckets[0].sessions.value
      end

      if b.streams?
        obj.streams = {}
        b.streams.buckets.each do |sb|
          obj.streams[ sb['key'] ] = { requests:sb.doc_count, duration:sb.duration.value, listeners:(sb.duration.value / context.period_length).round() }
        end
      end

      if b.rewind?
        obj.rewind = {}
        b.rewind.buckets.each do |sr|
          obj.rewind[ sr['key'] ] = { duration:sr.duration.value, listeners:(sr.duration.value / context.period_length).round() }
        end
      end

      if b.clients?
        obj.clients = {}
        b.clients.buckets.each do |key,cli|
          obj.clients[ key ] = { duration:cli.duration.value, listeners:(cli.duration.value / context.period_length).round() }
        end
      end

      obj
    end
  end
end