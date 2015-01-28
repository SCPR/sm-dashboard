class FetchListening
  include Interactor::Organizer

  before do
    context.index = "listens"
    context.aggs = [:streams,:duration,:clients]
    context.period_length = 10.minutes
    context.period_string = "10m"
  end

  organize Common::DetermineStartFinish, Common::DetermineIndices, Listening::Fetch, Listening::CleanUpResults
end