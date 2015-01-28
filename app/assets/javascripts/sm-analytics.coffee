class SM_Analytics
    @STREAMS: ['kpcc-aac-256','kpcc-aac-128','kpcc-aac-64','kpcclive']
    @STREAM_GROUPS: [['kpcc-aac-256','kpcc-aac-128','kpcc-aac-64'],["kpcclive"]]
    @REWINDS: ['0.0-60.0','60.0-900.0','900.0-3600.0','3600.0-*']

    constructor: (opts) ->
        @target = $(opts.target)

        console.log "SM Running!"

        @data_points = new SM_Analytics.DataPoints


        @data_points.on "reset", =>
            console.log "should draw graph(s)"

            @c3_g = new SM_Analytics.C3ListenersGraph collection:@data_points
            @target.append @c3_g.el
            @c3_g.render()

        # make our initial request
        $.getJSON "/api/listens", (data) =>
            @data_points.reset(data)

    #----------

    draw_chart: ->

    #----------

    class @C3ListenersGraph extends Backbone.View
        className: "c3"

        initialize: ->
            @chart = c3.generate
                bindto: @el,
                data:
                    type: "line"
                    columns: @_data()
                    x: "x"
                    groups: SM_Analytics.STREAM_GROUPS
                axis:
                    x:
                        type: "timeseries"
                        tick:
                            format: "%H:%M"
                            count: 24
                point:
                    show: false

        _data: ->
            data = ( [s] for s in SM_Analytics.STREAMS )
            x = ["x"]

            totals = ["Total"]

            for m in @collection.models
                s = m.get("series")

                x.push m.get("time")
                totals.push ( m.get("duration") / 600 )

                for i in [0..3]
                    l = Math.floor(s[i] / 600)
                    data[i].push l

            [x,data...]

        render: ->
            @chart.resize()
            setTimeout =>
                @chart.flush()
            , 300
            @

    #----------

    class @DataPoint extends Backbone.Model
        idAttribute: "_time"

        constructor: (data,opts) ->
            data._time = data.time
            data.time = new Date(data.time)

            data.series = ( ( data.streams[k]?.duration || 0 ) for k in SM_Analytics.STREAMS )
            data.rewinds = ( ( data.rewind[k]?.duration || 0 ) for k in SM_Analytics.REWINDS )

            super data, opts

    #----------

    class @DataPoints extends Backbone.Collection
        model: SM_Analytics.DataPoint

        asDataArray: ->
            keys = ['value1','value2','value3']

            @models.map (m) -> _.extend date:m.get('time'), _.object(keys,m.get('series'))

        asSeriesArray: ->

    #----------

window.SM_Analytics = SM_Analytics