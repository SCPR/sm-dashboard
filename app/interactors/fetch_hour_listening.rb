class FetchHourListening
  include Interactor::Organizer

  before do
    context.index         = "listens"
    context.aggs          = [:streams,:clients]
    context.period_length = 1.hour
    context.period_string = "1h"
  end

  organize Common::DetermineStartFinish, Common::DetermineIndices, Listening::Fetch, Listening::CleanUpResults
end