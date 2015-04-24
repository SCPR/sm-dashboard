module Common
  class FetchSchedule
    include Interactor

    def call
      # Given context.start and context.finish, fill in a context.schedule

      resp = Faraday.get "http://www.scpr.org/api/v3/schedule", {
        start_time:   context.start.to_i,
        length:       (context.finish - context.start).to_i,
      }

      obj = Hashie::Mash.new(JSON.parse(resp.body))

      context.schedule = obj.schedule_occurrences.collect do |so|
        start_t = Time.zone.parse(so.starts_at)
        end_t   = Time.zone.parse(so.ends_at)
        Hashie::Mash.new({
          title:      so.title,
          starts_at:  start_t,
          ends_at:    end_t,
          _duration:  (end_t - start_t).to_i,
        })
      end

      context.start   = context.schedule.first.starts_at
      context.finish  = context.schedule.last.ends_at
    end
  end
end