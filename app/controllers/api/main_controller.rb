module Api
  class MainController < ApplicationController
    def hour
      results = FetchThisHour.call(default_params)
      render json:{listens:results.listens,sessions:results.sessions}
    end

    def sessions
      results = FetchSessions.call(default_params)
      render json:results.results
    end

    private
    def default_params
      params.permit(:start,:limit)
    end
  end
end