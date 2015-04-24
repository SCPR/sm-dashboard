class FetchListening
  include Interactor::Organizer

  ALLOWED_PERIODS = {
    "1m"  => 1.minutes,
    "5m"  => 5.minutes,
    "10m" => 10.minutes,
    "15m" => 15.minutes,
    "30m" => 30.minutes,
    "1h"  => 1.hour,
  }

  before do
    context.index = "listens"
    context.aggs = [:streams,:duration,:clients]

    if context.period && ALLOWED_PERIODS[context.period]
      context.period_length = ALLOWED_PERIODS[context.period]
      context.period_string = context.period
    else
      context.period_length = 10.minutes
      context.period_string = "10m"
    end
  end

  organize Common::DetermineStartFinish, Common::DetermineIndices, Listening::Fetch, Listening::CleanUpResults
end