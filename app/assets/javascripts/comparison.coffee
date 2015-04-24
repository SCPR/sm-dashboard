class window.SM_Comparison extends Backbone.View
    className: "comp"

    initialize: ->
        @width = 800
        @height = 150

        @_x = d3.time.scale().range([0,@width])
        @_y = d3.scale.linear().range([@height,0])

        @_xaxis = d3.svg.axis().scale(@_x).orient("bottom")
        @_yaxis = d3.svg.axis().scale(@_y).orient("left").ticks(5)

        _this = @
        @_line = d3.svg.area().interpolate("basis")
            .x( (d) -> _this._x(d.get("time")) )
            .y( (d) -> _this._y(d.get("value")) )

        @_area = d3.svg.area()
            .interpolate("basis")
            .x( (d) -> _this._x(d.get("time")) )
            .y1( (d) -> _this._y(d.get("value")) )

        @_svg = d3.select(@el).append("svg")
            .attr("width", "100%")
            .attr("height", "100%")
            .append("g")

    render: ->
        # -- grab our dimensions -- #

        @width  = @$el.width()
        @height = @$el.height()

        @left = 35
        @bottom = 20

        # -- update our axis ranges -- #

        @_x.range([@left,@width])
        @_y.range([@height-@bottom,0])

        @_yaxis.tickSize(-@width,0)

        # -- build a chart -- #

        _this = @

        @_x.domain d3.extent @collection.models, ( (m) -> m.get("time") )

        ydomain = [
            d3.min(@collection.models, ( (m) -> Math.min(m.get("value"),m.get("prev")) )),
            d3.max(@collection.models, ( (m) -> Math.max(m.get("value"),m.get("prev")) ))
        ]

        @_y.domain ydomain

        console.log "y domain is ", ydomain

        @_svg.datum(@collection.models)

        @_svg.append("clipPath")
            .attr("id","clip-below")
            .append("path")
            .attr("d",@_area.y0(@height))

        @_svg.append("clipPath")
            .attr("id","clip-above")
            .append("path")
            .attr("d",@_area.y0(0))

        @_svg.append("path")
            .attr("class","area above")
            .attr("clip-path","url(#clip-above)")
            .attr("d", @_area.y0( (d) -> _this._y(d.get("prev")) ))

        @_svg.append("path")
            .attr("class","area below")
            .attr("clip-path","url(#clip-below)")
            .attr("d",@_area)

        @_svg.append("path")
            .attr("class","line")
            .attr("d",@_line)

        # -- axis -- #

        @_svg.append("g")
            .attr("class","x axis")
            .attr("transform","translate(0,#{@height - @bottom})")
            .call(@_xaxis)

        @_svg.append("g")
            .attr("class","y axis")
            .attr("transform","translate(#{@left - 4},0)")
            .call(@_yaxis)
            .append("text")
            .attr("transform","rotate(-90)")
            .attr("y",6)
            .attr("dy",".71em")
            .attr("x",-@margin)
            .style("text-anchor","end")
            .text("Listeners")
