class FetchScheduleListening
  include Interactor::Organizer

  before do
    context.index         = "listens"
    context.aggs          = [:cume,:duration,:starts]
    context.period_length = 30.minutes
  end

  organize Common::DetermineStartFinish, Common::DetermineIndices, Common::FetchSchedule, Listening::Fetch, Listening::CleanUpResults
end