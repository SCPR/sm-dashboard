class FetchListening
  include Interactor::Organizer

  organize Listening::DetermineStartFinish, Listening::DetermineIndices, Listening::Fetch, Listening::CleanUpResults
end