module Listening
  class Fetch
    include Interactor

    def call
      # -- Which Aggregations? -- #

      aggs = {}

      if context.aggs.include?(:sessions)
        aggs[:sessions] = {
          cardinality: {
            field: "session_id.keyword",
            precision_threshold: 1000,
          }
        }
      end

      if context.aggs.include?(:streams)
        aggs[:streams] = {
          terms: {
            field:  "stream.keyword",
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
              "kpcc-ios"      => { prefix: { "client.ua.keyword" => "KPCCiOS" }},
              "kpcc-iphone"   => { prefix: { "client.ua.keyword" => "KPCCiPhone" }},
              "scprweb"       => { prefix: { "client.ua.keyword" => "SCPRWEB" }},
              "kpcc-ipad"     => { prefix: { "client.ua.keyword" => "SCPRIPAD" }},
              "old-iphone"    => { prefix: { "client.ua.keyword" => "KPCCPublicRadioiPhoneApp" }},
              "kpcc-android"  => { prefix: { "client.ua.keyword" => "KPCCAndroid" }},
              "iheartradio"   => { prefix: {"client.ua.keyword" =>  "iheartradio"}}
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

      if context.aggs.include?(:cume)
        aggs[:cume] = {
          cardinality: {
            field: "client.ip.keyword",
            precision_threshold: 1000
          }
        }
      end

      if context.aggs.include?(:starts)
        aggs[:starts] = {
          range: {
            field: "session_duration",
            ranges: [{ from:60, to:90 }]
          },
          aggs: {
            sessions: {
              cardinality: {
                field: "session_id",
                precision_threshold: 1000
              }
            }
          }
        }
      end

      # -- Periods? -- #

      if context.single_period
        aggs = aggs
      elsif context.schedule
        aggs = {
          schedule: {
            date_range: {
              field:    "time",
              ranges:   context.schedule.map { |s| { from:s.starts_at, to:s.ends_at } }
            },
            aggs: aggs
          }
        }
      else
        aggs = {
          periods: {
            date_histogram: {
              field:    "time",
              interval: context.period_string,
              min_doc_count: 0
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
              bool: {
                must: [
                  {
                    match: {
                      type: 'listen'
                    }
                  },
                  {
                    range: {
                      time: {
                        gte:  context.start,
                        lt:   context.finish,
                      }
                    }
                  },
                  {
                    range: {
                      session_duration: {
                        gte: 60
                      }
                    }
                  }

                ]
              }
            }
          }
        },
        size: 0,
        aggs: aggs
      }
      context._body = body
      context._results = Hashie::Mash.new( ES_CLIENT.search index: context.indices, ignore_unavailable:true, body:body)
    end
  end
end