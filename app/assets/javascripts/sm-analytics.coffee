class SM_Analytics
    @STREAMS: ['kpcc-aac-256','kpcc-aac-128','kpcc-aac-64']
    @REWINDS: ['0.0-60.0','60.0-900.0','900.0-3600.0','3600.0-*']

    constructor: (opts) ->
        @target = $(opts.target)

        console.log "SM Running!"

        @data_points = new SM_Analytics.DataPoints


        @data_points.on "reset", =>
            console.log "should draw graph(s)"

            @rickshaw_g = new SM_Analytics.RickshawStreamListenersGraph collection:@data_points
            @target.append @rickshaw_g.el
            @rickshaw_g.render()

            @rewind_g = new SM_Analytics.RickshawRewindGraph collection:@data_points
            @target.append @rewind_g.el
            @rewind_g.render()

        # make our initial request
        $.getJSON "/api/listens", (data) =>
            @data_points.reset(data)

    #----------

    draw_chart: ->

    #----------

    class @RickshawRewindGraph extends Backbone.View
        className: "dashboard_rickshaw rewind"

        initialize: ->
            @$el.html "<div class='y_axis'></div><div class='chart'></div>"

            @graph = new Rickshaw.Graph
                element:        @$(".chart")[0]
                series:         @_dataAsSeriesArray()
                width:          800
                height:         250
                renderer:       "stack"

            @x_axis = new Rickshaw.Graph.Axis.Time graph:@graph #, timeUnit:(new Rickshaw.Fixtures.Time).unit("hour")
            @y_axis = new Rickshaw.Graph.Axis.Y
                graph:          @graph
                orientation:    'left'
                element:        @$('.y_axis')[0]

            @hover = new Rickshaw.Graph.HoverDetail graph:@graph

        _dataAsSeriesArray: ->
            palette = new Rickshaw.Color.Palette scheme:"spectrum14"

            data = ( name:s, data:[], color:palette.color() for s in SM_Analytics.REWINDS )

            for m in @collection.models
                s = m.get("rewinds")

                t = (Number(m.get("time")) / 1000)
                for i in [0..3]
                    l = Math.floor(s[i] / 60)
                    data[i].data.push x:t, y:l

            data

        render: ->
            @graph.render()
            @

    #----------

    class @RickshawStreamListenersGraph extends Backbone.View
        className:  "dashboard_rickshaw"

        initialize: ->
            @ema_periods = 30

            # set up our DOM
            @$el.html "<div class='y_axis'></div><div class='chart'></div>"

            @graph = new Rickshaw.Graph
                element:        @$(".chart")[0]
                series:         @_dataAsSeriesArray()
                width:          800
                height:         400
                interpolation:  "basis"
                renderer:       "multi"

            @x_axis = new Rickshaw.Graph.Axis.Time graph:@graph #, timeUnit:(new Rickshaw.Fixtures.Time).unit("hour")
            @y_axis = new Rickshaw.Graph.Axis.Y
                graph:          @graph
                orientation:    'left'
                element:        @$('.y_axis')[0]

            @hover = new Rickshaw.Graph.HoverDetail graph:@graph

        #----------

        _dataAsSeriesArray: ->
            palette = new Rickshaw.Color.Palette scheme:"spectrum14"

            data = ( name:s, data:[], color:palette.color(), renderer:"stack" for s in SM_Analytics.STREAMS )

            averaged = name:"Averaged Total", data:[], color:'black', renderer:"line"

            ema = null

            # use ten periods...
            ema_p = 2 / ( @ema_periods + 1 )

            for m in @collection.models
                s = m.get("series")

                total = 0

                t = (Number(m.get("time")) / 1000)
                for i in [0..2]
                    l = Math.floor(s[i] / 60)
                    data[i].data.push x:t, y:l
                    total += l

                ema = if ema then ( total * ema_p ) + ( ema * (1 - ema_p) ) else total
                averaged.data.push x:t, y:ema

            [data...,averaged]

        #----------

        render: ->
            @graph.configure series:@_dataAsSeriesArray()
            @graph.render()
            @

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