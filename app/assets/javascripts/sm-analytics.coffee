#= require_tree ./templates
#= require "./comparison"

class SM_Analytics
    @STREAMS: ['kpcc-aac-192','kpcc-aac-48','kpcclive','aac','kpccpfs']
    @STREAM_GROUPS: [['kpcc-aac-192','kpcc-aac-48'],["kpcclive"],["aac"],["kpccpfs"]]
    @REWINDS: ['0.0-120.0','120.0-900.0','900.0-3600.0','3600.0-*']
    @CLIENTS: ['kpcc-iphone','kpcc-ipad','scprweb','old-iphone']
    @CLIENT_LABELS: ['iPhone App','iPad App','SCPR.org','Old iPhone']

    @SESSION_DUR_BUCKETS = ["1-10min","10-30min","30-90min","90min - 4hr","4hr+"]

    DefaultOpts:
        fetch_listens:      true
        fetch_sessions:     true
        listens_endpoint:   "/api/listens"
        sessions_endpoint:  "/api/sessions"
        graph_type:         "line"
        generic_keys:       ["TLH","cume"]

    constructor: (opts={}) ->
        @opts = _.defaults opts, @DefaultOpts

        @data_points = new SM_Analytics.DataPoints

        @data_points.on "reset", =>
            if @opts.fetch_listens && $("#graph-listeners").length > 0
                @c3_g = new SM_Analytics.C3ListenersGraph collection:@data_points, graph_type:@opts.graph_type
                $("#graph-listeners").html @c3_g.el
                @c3_g.render()

            if @opts.fetch_listens && $("#graph-generic").length > 0
                @c3_gen = new SM_Analytics.C3Generic collection:@data_points, graph_type:@opts.graph_type, keys:@opts.generic_keys
                $("#graph-generic").html @c3_gen.el
                @c3_gen.render()

        if @opts.fetch_sessions
            @sessions = new SM_Analytics.Sessions

            @sessions.on "reset", =>
                if $("#graph-sessions")
                    @g_sessions = new SM_Analytics.C3SessionsGraph collection:@sessions
                    $("#graph-sessions").html @g_sessions.el
                    @g_sessions.render()

        # -- make our initial requests -- #

        if @opts.fetch_listens
            $.getJSON @opts.listens_endpoint, (data) =>
                @data_points.reset(data)

        if @opts.fetch_sessions
            $.getJSON @opts.sessions_endpoint, (data) =>
                @sessions.reset(data.periods)

        # -- set up "This Hour" top line -- #

        if $("#top-line")
            @this_hour = new SM_Analytics.ThisHour
            @hour_view = new SM_Analytics.ThisHourView model:@this_hour
            $("#top-line").html @hour_view.el
            @hour_view.render()
            @this_hour.fetch()

            setInterval =>
                @this_hour.fetch()
            , 60*1000 # one minute

    #----------

    class @C3Generic extends Backbone.View
        className: "c3 c3_generic"

        initialize: (@opts) ->
            @_x = @opts.x || "time"

            @_xopts =
                if @_x == "time"
                    type: "timeseries"
                    tick:
                        format: "%H:%M"
                        count: 24
                else
                    type: "category"

            @chart = c3.generate
                bindto: @el,
                data:
                    type: @opts.graph_type
                    columns: @_data()
                    x: "x"
                axis:
                    x:  @_xopts
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
            data = ( [k] for k in @opts.keys )
            x = ["x"]

            for m in @collection.models
                x.push m.get(@_x)

                for k,idx in @opts.keys
                    data[idx].push m.get(k) || 0

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
            @_cohorts = [SM_Analytics.CLIENT_LABELS...,"Other"]

            @chart = c3.generate
                bindto: @el,
                data:
                    columns: @_data()
                    x: "x"
                    groups: [@_cohorts]
                    type: "area-spline"
                axis:
                    x:
                        type: "timeseries"
                        tick:
                            fit: true
                            format: "%H:%M"
                grid:
                    y:
                        show: true
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
            data = ( [s] for s in @_cohorts )

            x = ["x"]

            for m in @collection.models
                x.push m.get("time")
                c = m.get("clients")

                client_total = 0
                for key,idx in SM_Analytics.CLIENTS
                    if c[key]
                        data[idx].push c[key].listeners
                        client_total += c[key].listeners
                    else
                        data[idx].push 0

                data[data.length-1].push m.get("listeners") - client_total

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
                grid:
                    y:
                        show: true
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
            data = [['x','Current','Vs. 24 Hours Earlier','Vs. One Week Earlier' ]]

            for m in @collection.models
                #data.push [m.get("time"),( m.get("value") - m.get("y_value")),(m.get("value") - m.get("w_value"))]
                data.push [m.get("time"),m.get("value"),m.get("y_value"),m.get("w_value")]

            data

        render: ->
            @chart.resize()
            setTimeout =>
                @chart.flush()
            , 300
            @

    #----------

    class @Schedule
        constructor: ->
            @data_points = new SM_Analytics.DataPoints

            @data_points.on "reset", =>
                @c3_sched = new SM_Analytics.C3Generic collection:@data_points, x:"title", keys:["cume","listeners","starts"], graph_type:"bar"
                $("#graph-schedule").html @c3_sched.el
                @c3_sched.render()

            $.getJSON "/api/schedule", (data) =>
                @data_points.reset(data)

    class @Comparison
        DefaultOpts:
            endpoint: "/api/listens/compare"

        constructor: (opts) ->
            @opts = _.defaults opts, @DefaultOpts

            @data_points = new SM_Analytics.CompPoints

            @data_points.on "reset", =>
                console.log "should draw graph(s)"

                #@c3_comp = new SM_Analytics.C3CompGraph collection:@data_points
                #$("#graph-compare").html @c3_comp.el
                #@c3_comp.render()

                @graph = new SM_Comparison collection:@data_points
                $("#graph-compare").html @graph.el
                @graph.render()

            $.getJSON @opts.endpoint, (data) =>
                # we want to loop through data.today, and map the values from
                # data.yesterday and data.week_ago into it.

                values = []

                for d,idx in data.today
                    #yest = data.yesterday[idx]
                    week = data.week_ago[idx]

                    obj =
                        time:       d.time
                        value:      d.listeners
                        prev:       week.listeners
                        prev_time:  week.time
                        #y_time:     yest.time
                        #y_value:    yest.listeners
                        #w_time:     week.time
                        #w_value:    week.listeners

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

            if data.duration
                data.TLH = Math.round(data.duration / 3600)

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