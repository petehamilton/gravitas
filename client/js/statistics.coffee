class @Statistics
  constructor: (@chartPaper, @piePaper) ->
    log "cp", @chartPaper
    log "pp", @piePaper
    @pieChart = @drawPieChart(43,31)
    graphLabel = chartPaper.text(200, 10, "RATING CHANGES")
    graphLabel2 = piePaper.text(310, 10, "WIN RATIO")

    graphLabel.attr fill: "#68727b", 'font-weight': "bold", 'font-size': 12, 'font-family': "Century Gothic, sans-serif"
    graphLabel2.attr fill: "#68727b", 'font-weight': "bold", 'font-size': 12, 'font-family': "Century Gothic, sans-serif"

    @ratingValues = [ 1121, 943, 1200, 1366, 1665, 1732, 1554 ]
    @graph = @drawLineGraph(@ratingValues)

  # Draws the win:loss piechart
  drawPieChart: (winsNumber,lossNumber) ->
    @piechart? @piechart.remove
    @piechart = @piePaper.piechart(140, 30, 30, [winsNumber,lossNumber],
      {legend: ["%% - win", "%% - loss"], legendpos: "west", legendcolor: '#68727b', colors:["#50a20e","#a20e0f"], smooth: true, stroke: "#000"})

  # Draws the rating line graph
  drawLineGraph: (ratingValues) ->
    @graph? @graph.remove
    xAxisValues = []
    i = ratingValues.length
    while i > 0
      date = new Date()
      date.setDate date.getDate() - i
      xAxisValues.push date.getTime()
      i--
    chart = @chartPaper.linechart(20, 12, 400, 100, xAxisValues, ratingValues,
      colors: [ "#50a20e" ]
      nostroke: false
      axis: "0 0 1 1"
      symbol: "circle"
      smooth: true
    ).hoverColumn(->
      @tags = @paper.set()
      @tags.push @paper.label(@x, @y[0], @values[0], 160, 10).insertBefore(this).attr([{ fill: "#fff" }, {fill: this.symbols[0].attr("fill") }])
    , ->
      @tags and @tags.remove()
    )
    axisItems = chart.axis[0].text.items
    i = 0
    l = axisItems.length

    while i < l
      date = new Date(parseInt(axisItems[i].attr("text")))
      axisItems[i].attr "text", dateFormat(date, "dd.mm.yy")
      i++

    $.each chart.axis[0].text.items, (i, label) ->
      label.attr fill: "#68727b"

    $.each chart.axis[1].text.items, (i, label) ->
      label.attr fill: "#68727b"
