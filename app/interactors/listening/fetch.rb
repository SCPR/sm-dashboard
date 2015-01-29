module Listening
  class Fetch
    include Interactor

    def call
      # -- Which Aggregations? -- #

      aggs = {}

      if context.aggs.include?(:sessions)
        aggs[:sessions] = {
          cardinality: {
            field: "session_id",
            precision_threshold: 100,
          }
        }
      end

      if context.aggs.include?(:streams)
        aggs[:streams] = {
          terms: {
            field:  "stream",
            size:   10,
          },
          aggs: {
            duration: { sum: { field: "duration" } },
          }
        }
      end

      if context.aggs.include?(:duration)
        aggs[:duration] = {
          sum: { field: "duration" }
        }
      end

      if context.aggs.include?(:avg_duration)
        aggs[:avg_duration] = {
          percentiles: { field: "session_duration", percents:[50] }
        }
      end

      if context.aggs.include?(:clients)
        aggs[:clients] = {
          filters: {
            filters: {
              "kpcc-iphone" => { term: { "client.ua" => "kpcciphone" }},
              "scprweb" => { term: { "client.ua" => "scprweb" }}
            }
          },
          aggs: {
            duration: { sum: { field: "duration"} }
          }
        }
      end

      if context.aggs.include?(:rewind)
        aggs[:rewind] = {
          range: {
            field: "offsetSeconds",
            ranges: [
              { from:0, to:120 },
              { from:120, to:900 },
              { from:900, to:3600 },
              { from:3600 }
            ]
          },
          aggs: {
            duration: {
              sum: { field: "duration" }
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

      context._results = Hashie::Mash.new( ES_CLIENT.search index:context.indices, ignore_unavailable:true, type:"listen", body:body)
    end
  end
end