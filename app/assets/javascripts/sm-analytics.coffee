#= require_tree ./templates

class SM_Analytics
    @STREAMS: ['kpcc-aac-256','kpcc-aac-128','kpcc-aac-64','kpcclive','aac']
    @STREAM_GROUPS: [['kpcc-aac-256','kpcc-aac-128','kpcc-aac-64'],["kpcclive"],["aac"]]
    @REWINDS: ['0.0-120.0','120.0-900.0','900.0-3600.0','3600.0-*']
    @CLIENTS: ['kpcc-iphone','kpcc-ipad','scprweb','old-iphone']

    @SESSION_DUR_BUCKETS = ["1-10min","10-30min","30-90min","90min - 4hr","4hr+"]

    constructor: (opts) ->
        console.log "SM Running!"

        @data_points = new SM_Analytics.DataPoints

        @data_points.on "reset", =>
            console.log "should draw graph(s)"

            @c3_g = new SM_Analytics.C3ListenersGraph collection:@data_points
            $("#graph-listeners").html @c3_g.el
            @c3_g.render()

            @c3_ua = new SM_Analytics.C3UAGraph collection:@data_points
            $("#graph-clients").html @c3_ua.el
            @c3_ua.render()

        @sessions = new SM_Analytics.Sessions

        @sessions.on "reset", =>
            @g_sessions = new SM_Analytics.C3SessionsGraph collection:@sessions
            $("#graph-sessions").html @g_sessions.el
            @g_sessions.render()

        # -- make our initial requests -- #

        $.getJSON "/api/listens", (data) =>
            @data_points.reset(data)

        $.getJSON "/api/sessions", (data) =>
            @sessions.reset(data.periods)

        # -- set up "This Hour" top line -- #

        @this_hour = new SM_Analytics.ThisHour
        @hour_view = new SM_Analytics.ThisHourView model:@this_hour
        $("#top-line").html @hour_view.el
        @hour_view.render()
        @this_hour.fetch()

        setInterval =>
            @this_hour.fetch()
        , 60*1000 # one minute

    #----------

    class @C3UAGraph extends Backbone.View
        className: "c3 c3_ua"

        initialize: ->
                @chart = c3.generate
                    bindto: @el,
                    data:
                        type: "line"
                        columns: @_data()
                        x: "x"
                    axis:
                        x:
                            type: "timeseries"
                            tick:
                                format: "%H:%M"
                                count: 24
                    point:
                        show: true
                    transition:
                        duration: 0
                    point:
                        r:  1
                        focus:
                            expand:
                                r: 4

            _data: ->
                data = ( [s] for s in SM_Analytics.CLIENTS )
                x = ["x"]

                for m in @collection.models
                    c = m.get("clients")

                    x.push m.get("time")

                    for key,idx in SM_Analytics.CLIENTS
                        if c[key]
                            data[idx].push c[key].listeners
                        else
                            data[idx].push 0

                [x,data...]

            render: ->
                @chart.resize()
                setTimeout =>
                    @chart.flush()
                , 300
                @

    #----------

    class @C3ListenersGraph extends Backbone.View
        className: "c3"

        initialize: ->
            @chart = c3.generate
                bindto: @el,
                data:
                    columns: @_data()
                    x: "x"
                    groups: SM_Analytics.STREAM_GROUPS
                    type: "spline"
                axis:
                    x:
                        type: "timeseries"
                        tick:
                            format: "%H:%M"
                            count: 24
                point:
                    show: true
                transition:
                    duration: 0
                point:
                    r:  1
                    focus:
                        expand:
                            r: 4

        _data: ->
            data = ( [s] for s in SM_Analytics.STREAMS )
            x = ["x"]

            totals = ["Total"]

            for m in @collection.models
                x.push m.get("time")
                totals.push m.get("listeners")

                streams = m.get("streams")
                for key,idx in SM_Analytics.STREAMS
                    data[idx].push streams[key]?.listeners || 0

            [x,data...]

        render: ->
            @chart.resize()
            setTimeout =>
                @chart.flush()
            , 300
            @

    #----------

    class @C3SessionsGraph extends Backbone.View
        className: "c3 c3_sessions"

        initialize: ->
            @chart = c3.generate
                bindto: @el,
                data:
                    columns: @_data()
                    type: "bar"
                axis:
                    x:
                        type: "category",
                        categories: SM_Analytics.SESSION_DUR_BUCKETS
                transition:
                    duration: 0
                bar:
                    zerobased: true
                legend:
                    hide: true

        _data: ->
            totals = {}
            for k in SM_Analytics.SESSION_DUR_BUCKETS
                totals[k] = 0

            for m in @collection.models
                for k,v of m.get("duration")
                    totals[k] += v

            console.log "totals is ", totals

            t_arr = ["durations",( totals[k] for k in SM_Analytics.SESSION_DUR_BUCKETS )...]
            [t_arr]

        render: ->
            @chart.resize()
            setTimeout =>
                @chart.flush()
            , 300
            @

    #----------

    class @C3CompGraph extends Backbone.View
        initialize: ->
            @chart = c3.generate
                bindto: @el,
                data:
                    rows:   @_data()
                    x:      "x"
                    type:   "spline"
                    colors:
                        today:      "#0000aa",
                        yesterday:  "#777"
                        week_ago:   "#aaa"
                axis:
                    x:
                        type: "timeseries"
                        tick:
                            format: "%H:%M"
                            count: 24
                point:
                    show: true
                transition:
                    duration: 0
                point:
                    r:  1
                    focus:
                        expand:
                            r: 4

        _data: ->
            # data as rows...
            data = [['x','today','yesterday','week_ago' ]]

            for m in @collection.models
                data.push [m.get("time"),m.get("value"),m.get("y_value"),m.get("w_value")]

            data

        render: ->
            @chart.resize()
            setTimeout =>
                @chart.flush()
            , 300
            @

    #----------

    class @Comparison
        constructor: ->
            @data_points = new SM_Analytics.CompPoints

            @data_points.on "reset", =>
                console.log "should draw graph(s)"

                @c3_comp = new SM_Analytics.C3CompGraph collection:@data_points
                $("#graph-compare").html @c3_comp.el
                @c3_comp.render()


            $.getJSON "/api/listens/compare", (data) =>
                # we want to loop through data.today, and map the values from
                # data.yesterday and data.week_ago into it.

                values = []

                for d,idx in data.today
                    yest = data.yesterday[idx]
                    week = data.week_ago[idx]

                    obj =
                        time:       d.time
                        value:      d.listeners
                        y_time:     yest.time
                        y_value:    yest.listeners
                        w_time:     week.time
                        w_value:    week.listeners

                    values.push obj

                @data_points.reset(values)

    #----------

    class @ThisHour extends Backbone.Model
        url: "/api/hour"

    class @ThisHourView extends Backbone.View
        template: JST['this_hour']

        initialize: ->
            @model.on "change", =>
                @render()

        render: ->
            @$el.html @template @model.toJSON()

            @

    #----------

    class @DataPoint extends Backbone.Model
        idAttribute: "_time"

        constructor: (data,opts) ->
            data._time = data.time
            data.time = new Date(data.time)

            super data, opts

    #----------

    class @DataPoints extends Backbone.Collection
        model: SM_Analytics.DataPoint

    #----------

    class @SessionPeriod extends @DataPoint

    class @Sessions extends @DataPoints
        model: SM_Analytics.SessionPeriod

    #----------

    class @CompPoints extends @DataPoints

window.SM_Analytics = SM_Analytics