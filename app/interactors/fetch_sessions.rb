class FetchSessions
  include Interactor::Organizer

  before do
    context.index = "sessions"
    context.aggs = [:duration]
    context.period_length = 10.minutes
    context.period_string = "10m"
  end

  organize Common::DetermineStartFinish, Common::DetermineIndices, Sessions::Fetch
end