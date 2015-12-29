class window.SM_Plus extends Backbone.View
    @PLUS_STREAMS: ['kpcc-plus-mp3','kpcc-plus-48','kpcc-plus-192']
    @PLUS_GROUPS: [['kpcc-plus-mp3'],['kpcc-plus-48','kpcc-plus-192']]
    @PLUS_GROUP_LABELS: ['Plus Web','Plus iPhone']

    class_name: "plus"

    initialize: ->
        @_cohorts = [SM_Plus.PLUS_GROUP_LABELS...,"Non-Plus"]

        @_labelTimeFormat = d3.time.format("%-I:%M%p")

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
                        format: "%-I:%M%p"
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
            tooltip:
                format:
                    title: (x) =>
                        point = @collection.findWhere(time:x)
                        @_labelTimeFormat(x) + " (#{point?.get("listeners")||"??"})"

    _data: ->
        data = ( [s] for s in @_cohorts )

        x = ["x"]

        for m in @collection.models
            x.push m.get("time")
            c = m.get("streams")

            plus_total = 0
            for streams,idx in SM_Plus.PLUS_GROUPS
                gtotal = 0

                gtotal += (c[key]?.listeners || 0) for key in streams

                data[idx].push gtotal
                plus_total += gtotal

            data[data.length-1].push m.get("listeners") - plus_total

        [x,data...]

    render: ->
        @chart.resize()
        setTimeout =>
            @chart.flush()
        , 300
        @