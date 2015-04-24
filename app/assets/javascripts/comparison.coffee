class window.SM_Comparison extends Backbone.View
    className: "comp"

    initialize: ->
        @width = 800
        @height = 150
        @_rendered = false

        @_x = d3.time.scale().range([0,@width])
        @_y = d3.scale.linear().range([@height,0])

        @_xaxis = d3.svg.axis().scale(@_x).orient("bottom")
        @_yaxis = d3.svg.axis().scale(@_y).orient("left").ticks(5)

        _this = @

        # -- drawing functions -- #

        @_line = d3.svg.area().interpolate("basis")
            .x( (d) -> _this._x(d.get("time")) )
            .y( (d) -> _this._y(d.get("value")) )

        @_area = d3.svg.area()
            .interpolate("basis")
            .x( (d) -> _this._x(d.get("time")) )
            .y1( (d) -> _this._y(d.get("value")) )

        # -- set up svg elements -- #

        @_svg = d3.select(@el).append("svg")
            .attr("width", "100%")
            .attr("height", "100%")
            .append("g")

        @_svg.append("clipPath")
            .attr("id","clip-below")
            .append("path")

        @_svg.append("clipPath")
            .attr("id","clip-above")
            .append("path")

        @_svg.append("path")
            .attr("class","area above")
            .attr("clip-path","url(#clip-above)")

        @_svg.append("path")
            .attr("class","area below")
            .attr("clip-path","url(#clip-below)")

        @_svg.append("path")
            .attr("class","line")

        @_svg.append("g")
            .attr("class","x axis")

        @_svg.append("g")
            .attr("class","y axis")
            .append("text")
            .attr("transform","rotate(-90)")
            .attr("y",6)
            .attr("dy",".71em")
            .attr("x",0)
            .style("text-anchor","end")
            .text("Listeners")

        # -- re-render when the window size changes -- #

        $(window).resize =>
            if @_rendered
                @render()

        # -- update our domains if our data changes -- #

        @collection.on "change", => @_updateDomains()
        @_updateDomains()

    #----------

    _updateDomains: ->
        @_x.domain d3.extent @collection.models, ( (m) -> m.get("time") )

        @_y.domain [
            d3.min(@collection.models, ( (m) -> Math.min(m.get("value"),m.get("prev")) )),
            d3.max(@collection.models, ( (m) -> Math.max(m.get("value"),m.get("prev")) ))
        ]

    #----------

    render: ->
        @_rendered = true

        # -- grab our dimensions -- #

        @width  = @$el.width()
        @height = @$el.height()

        @left = 35
        @bottom = 20

        # -- update our axis ranges -- #

        @_x.range([@left,@width])
        @_y.range([@height-@bottom,0])

        # make our horizontal grid lines run all the way across
        @_yaxis.tickSize(-@width,0)

        # -- build a chart -- #

        _this = @

        @_svg.datum(@collection.models)

        @_svg.select("#clip-below path").attr("d",@_area.y0(@height))
        @_svg.select("#clip-above path").attr("d",@_area.y0(0))

        @_svg.select("path.area.above")
            .attr("d", @_area.y0( (d) -> _this._y(d.get("prev")) ))

        @_svg.select("path.area.below")
            .attr("d",@_area)

        @_svg.select("path.line").attr("d",@_line)

        # -- axis -- #

        @_svg.select("g.x.axis")
            .attr("transform","translate(0,#{@height - @bottom})")
            .call(@_xaxis)

        @_svg.select("g.y.axis")
            .attr("transform","translate(#{@left - 4},0)")
            .call(@_yaxis)
