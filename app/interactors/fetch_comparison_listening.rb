class FetchComparisonListening
  include Interactor

  before do
    context.index         = "listens"
    context.aggs          = [:duration]
    context.period_length = 10.minutes
    context.period_string = "10m"
  end

  # Comparison listening fetches a period, then the same period time one day
  # earlier and seven days earlier.
  def call
    # set start/finish for "today"
    _context = Common::DetermineStartFinish.call(context)

    # -- Fetch Today -- #

    today = _context.clone()
    today = Common::DetermineIndices.call(today)
    today = Listening::Fetch.call(today)
    today = Listening::CleanUpResults.call(today)

    # -- Fetch One Day Ago -- #

    yesterday           = _context.clone()
    yesterday[:start]   -= 1.day
    yesterday[:finish]  -= 1.day

    yesterday = Common::DetermineIndices.call(yesterday)
    yesterday = Listening::Fetch.call(yesterday)
    yesterday = Listening::CleanUpResults.call(yesterday)

    # -- Fetch One Week Ago -- #

    week_ago          = _context.clone()
    week_ago[:start]  -= 7.days
    week_ago[:finish] -= 7.days

    week_ago = Common::DetermineIndices.call(week_ago)
    week_ago = Listening::Fetch.call(week_ago)
    week_ago = Listening::CleanUpResults.call(week_ago)


    # -- Add to return context -- #

    context._today      = today
    context._yesterday  = yesterday
    context._week_ago   = week_ago

    context.results = Hashie::Mash.new({ today:today.results, yesterday:yesterday.results, week_ago:week_ago.results })
  end
end