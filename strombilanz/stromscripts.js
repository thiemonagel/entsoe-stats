var choiceContainer = $("#choices");
var plotContainer   = $("#flotdiv");

choiceContainer.append(
'<div class="butgroup" style="float:left">Jahre:<br />' +
'<input id="2009" checked="checked" name="2009" type="checkbox" /> <label for="2009">2009</label><br />' +
'<input id="2010" checked="checked" name="2010" type="checkbox" /> <label for="2010">2010</label><br />' +
'<input id="2011" checked="checked" name="2011" type="checkbox" /> <label for="2011">2011</label><br />' +
'&nbsp;' +
'</div>' +
'<div class="butgroup" style="float:left">Art der Darstellung:<br />' +
'<input id="1" name="datatype" type="radio" value="1" /> <label for="1">tagesgenau</label><br />' +
'<input id="7" name="datatype" type="radio" value="7" /> <label for="7">7-Tage-Durchschnitt</label><br />' +
'<input id="30" name="datatype" type="radio" checked="checked" value="30" /> <label for="30">30-Tage-Durchschnitt</label><br />' +
'<input id="cum" name="datatype" type="radio" value="cum" /> <label for="cum">kumulativ</label></br />' +
'</div>' +
'<div class="butgroup">Navigation:<br />' +
'<span id="smallgray">Darstellung vergrößern oder verkleinern: Mausrad<br />' +
'sichtbaren Ausschnitt verschieben: klicken und ziehen</span>' +
'</div>' +
'<div style="clear:both"></div>'
)

choiceContainer.find("input").click( plotAccordingToChoices )

// Date of "Moratorium"
var moradate = (new Date(1984, 3-1, 17)).getTime()

var plot
var last_datatype = "none"

// Triggered by panning and zooming.
function UpdateLabel() {
    var offset = plot.getPlotOffset()
    var o      = plot.pointOffset( { x: moradate, y: 0 } )
    var left   = o.left + 4
    var top    = offset.top + plot.height() - 26

    var m = $("#moratorium")
    if ( left >= offset.left ) {
        m.css( "left", left + "px" )
        m.css( "top",  top  + "px" )
        m.css( "display", "inline" )

        // draw a little arrow on top of the label
        var ctx = plot.getCanvas().getContext("2d")
        ctx.beginPath()
        ctx.moveTo(left, top)
        ctx.lineTo(left, top - 10)
        ctx.lineTo(left + 10, top - 5)
        ctx.lineTo(left, top)
        ctx.fillStyle = "#000"
        ctx.fill()
    } else {
        m.css( "display", "none" )
    }
}


// Initialize plot with data.
function InitPlot( data ) {
    var startdate  = (new Date(1984,  1-1,  1)).getTime()
    var enddate    = (new Date(1984, 12-1, 31)).getTime()
    var week       =   7. * 24. * 3600. * 1000.
    var year       = 365. * 24. * 3600. * 1000.

    // vertical line to denote time of moratorium
    var marking = [
        { color: '#000', lineWidth: 1, xaxis: { from: moradate, to: moradate } }
    ]

    // Plot once to obtain zoom range.
    plot = $.plot( plotContainer, data, {} )
    
    var yaxis  = plot.getAxes().yaxis
    var deltay = yaxis.max - yaxis.min

    // This time plot for real.
    plot = $.plot( plotContainer, data, {
        grid:   { markings: marking },
        legend: { position: "se", backgroundOpacity: .65 },
        xaxis:  { zoomRange: [ week, year ], panRange: [ startdate, enddate ], mode: "time" },
        yaxis:  { zoomRange: [ deltay/10., deltay*1.2 ] },
        pan:    { interactive: true },
        zoom:   { interactive: true, amount: 1.1 },
    })

    plotContainer.append('<div id="moratorium" style="position:absolute;white-space:nowrap;color:#666;font-size:smaller">AKW-Moratorium seit 17.3.2011</div>')

    // add zoom out button 
    $('<div class="button" style="position:absolute;cursor:pointer;right:10px;top:10px;font-size:smaller;background-color:#dddddd;padding:2px;opacity:.65">Ansicht zurücksetzen</div>').appendTo(plotContainer).click(function (e) {
        e.preventDefault()
        last_datatype = "none"
        plotAccordingToChoices()
    })


    // Register callbacks for panning and zooming.
    plotContainer.bind('plotpan', function (event, plot) {
        UpdateLabel()
    })    
    plotContainer.bind('plotzoom', function (event, plot) {
        UpdateLabel()
    })
}


function plotAccordingToChoices() {
//    console.log("plotAccordingToChoices() called.")

    var data = []
    
    var datatype = last_datatype
    choiceContainer.find("input:checked").each(function () {
        var key = $(this).attr("name")
        if ( key == "datatype" ) {
            datatype = $(this).attr("value")
        }
    })
    choiceContainer.find("input:checked").each(function () {
        var key = $(this).attr("name")
        if ( key != "datatype" ) {
            if (key && datasets[key+":"+datatype])
                data.push(datasets[key+":"+datatype])
        }
    })
    
    if ( datatype == last_datatype || data.length == 0 ) return

    if ( datatype == "cum" || last_datatype == "cum" || last_datatype == "none" ) {
        InitPlot( data )
    } else {
        plot.setData( data )
        plot.setupGrid()
        plot.draw()
    }

    UpdateLabel()
    last_datatype = datatype
}


plotAccordingToChoices()
