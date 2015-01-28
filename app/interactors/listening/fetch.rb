module Listening
  class Fetch
    include Interactor

    def call
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
        aggs: {
          minutes: {
            date_histogram: {
              field:    "time",
              interval: "10m",
            },
            aggs: {
              sessions: {
                cardinality: {
                  field: "session_id",
                  precision_threshold: 100,
                }
              },
              duration: {
                sum: { field: "duration" }
              },

              stream: {
                terms: {
                  field:  "stream",
                  size:   10,
                },
                aggs: {
                  duration: { sum: { field: "duration" } },
                }
              },
              rewind: {
                range: {
                  field: "offsetSeconds",
                  ranges: [
                    { from:0, to:60 },
                    { from:60, to:900 },
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
            }
          }
        }
      }

      context._body = body

      context._results = Hashie::Mash.new( ES_CLIENT.search index:context.indices, ignore_unavailable:true, type:"listen", body:body)
    end
  end
end