module Sessions
  class Fetch
    include Interactor

    def call
      # -- Which Aggregations? -- #

      aggs = {}

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
          range: {
            field: "duration",
            ranges: [
              { key:"1-10min",      from: 1.minute, to: 10.minutes },
              { key:"10-30min",     from: 10.minutes, to: 30.minutes },
              { key:"30-90min",     from: 30.minutes, to: 90.minutes },
              { key:"90min - 4hr",  from: 90.minutes, to: 4.hours },
              { key:"4hr+",         from: 4.hours }
            ],
            keyed: true
          },

        }
      end

      if context.aggs.include?(:connected)
        aggs[:connected] = {
          extended_stats: { field: "connected" }
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
              and: [
                {range: {
                  time: {
                    gte:  context.start,
                    lt:   context.finish,
                  }
                }},
                {range: {
                  duration: {
                    gte: 60
                  }
                }}
              ]
            }
          }
        },
        size: 0,
        aggs: aggs
      }

      context._body = body

      context._results = Hashie::Mash.new( ES_CLIENT.search index:context.indices, ignore_unavailable:true, type:"session", body:body)

      # -- Clean Up -- #

      results = Hashie::Mash.new({ sessions:context._results.hits.total })

      if context._results.aggregations?
        if context._results.aggregations.periods?
          clean = []
          context._results.aggregations.periods.buckets.each do |b|
            ts = Time.at(b['key'] / 1000)
            obj = self._clean(b,Hashie::Mash.new({time:ts.utc}))
            clean << obj
          end

          results.periods = clean
        else
          results.merge!(self._clean(context._results.aggregations,Hashie::Mash.new()))
        end
      end

      context.results = results

    end

    def _clean(b,obj)
      if b.duration?
        obj.duration = {}
        b.duration.buckets.each do |k,v|
          obj.duration[k] = v.doc_count
        end
      end

      obj
    end
  end
end