module Listening
  class FetchStarts
    include Interactor

    def call
      # -- Which Aggregations? -- #

      aggs = {}

      if context.aggs.include?(:streams)
        aggs[:streams] = {
          terms: {
            field:  "stream",
            size:   10,
          }
        }
      end

      if context.aggs.include?(:clients)
        aggs[:clients] = {
          filters: {
            filters: {
              "kpcc-iphone" => { term: { "client.ua" => "kpcciphone" }},
              "scprweb" => { term: { "client.ua" => "scprweb" }}
            }
          }
        }
      end

      # -- Periods? -- #

      if context.single_period
        aggs = aggs
      else
        aggs = {
          periods: {
            date_histogram: {
              field:    "time",
              interval: context.period_string,
            },
            aggs: aggs
          }
        }
      end

      # -- Build Query Body -- #

      body = {
        query: {
          constant_score: {
            filter: {
              range: {
                time: {
                  gte:  context.start,
                  lt:   context.finish,
                }
              }
            }
          }
        },
        size: 0,
        aggs: aggs
      }

      context._body = body

      context._results = Hashie::Mash.new( ES_CLIENT.search index:context.indices, ignore_unavailable:true, type:"start", body:body)

      # -- Clean up results -- #

      context.results = { starts:context._results.hits.total }
    end
  end
end