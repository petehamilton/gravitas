class @Statistics
  constructor: (@paper) ->
    @updatePieChart(43,31)


  # Updates the HP indicator
  updatePieChart: (winsNumber,lossNumber) ->
    @hp_indicator? @hp_indicator.remove
    @hp_indicator = @paper.piechart(125, 50, 30, [winsNumber,lossNumber],
      {legend: ["%% - win", "%% - loss"], legendpos: "west", legendcolor: '#68727b', colors:["#57ff53","#ae0800"], smooth: true, stroke: "#57ff53"})


