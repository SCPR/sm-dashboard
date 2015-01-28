class FetchThisHour
  include Interactor

  before do
    context.index = "listens"
    context.start = Time.now() - 1.hour
    context.finish = Time.now()
  end

  def call
    common_ctx = { period_length:1.hour, start:1.hour.ago.utc, finish:Time.now().utc, single_period:true }

    # -- Listener Info -- #

    listens_ctx = common_ctx.merge({ index:"listens", aggs:[:duration] })

    [Common::DetermineIndices,Listening::Fetch,Listening::CleanUpResults].each do |c|
      res = c.call(listens_ctx)
      if res.failed?
        break
      end

      listens_ctx = res
    end

    context.listens = listens_ctx.results

    # -- Starts Info -- #

    starts_ctx = common_ctx.merge({index:"listens",aggs:[]})

    [Common::DetermineIndices,Listening::FetchStarts].each do |c|
      res = c.call(starts_ctx)
      if res.failed?
        break
      end

      starts_ctx = res
    end

    context.starts = starts_ctx.results

    # -- Session Info -- #

    sessions_ctx = common_ctx.merge({index:"sessions", aggs:[] })

    [Common::DetermineIndices,Sessions::Fetch].each do |c|
      res = c.call(sessions_ctx)
      if res.failed?
        break
      end

      sessions_ctx = res
    end

    context.sessions = sessions_ctx.results

  end

end