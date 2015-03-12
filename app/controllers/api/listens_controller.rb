module Api
  class ListensController < ApplicationController

    def index
      results = FetchListening.call(listen_params)
      render :json => results.results
    end

    def compare
      results = FetchComparisonListening.call(listen_params)
      render :json => results.results
    end

    def hour
      results = FetchHourListening.call(listen_params)
      render :json => results.results
    end

    private
    def listen_params
      params.permit(:start,:limit)
    end
  end
end