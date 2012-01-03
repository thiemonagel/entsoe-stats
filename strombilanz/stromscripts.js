var choiceContainer = $("#choices");
var plotContainer   = $("#flotdiv");

choiceContainer.append(
'<div class="butgroup" id="yeardiv" style="float:left">Jahre:<br />' +
'</div>' +
'<div class="butgroup" id="countrydiv" style="float:left">Länder:<br />' +
'</div>' +
'<div class="butgroup" id="aggregationdiv" style="float:left">Art der Darstellung:<br />' +
'<input id="1" name="aggregation" type="radio" value="1" /> <label for="1">tagesgenau</label><br />' +
'<input id="7" name="aggregation" type="radio" value="7" /> <label for="7">7-Tage-Durchschnitt</label><br />' +
'<input id="30" name="aggregation" type="radio" checked="checked" value="30" /> <label for="30">30-Tage-Durchschnitt</label><br />' +
'<input id="cum" name="aggregation" type="radio" value="cum" /> <label for="cum">kumulativ</label></br />' +
'</div>' +
'<div class="butgroup">Navigation:<br />' +
'<span id="smallgray">Darstellung vergrößern oder verkleinern: Mausrad<br />' +
'sichtbaren Ausschnitt verschieben: klicken und ziehen</span>' +
'</div>' +
'<div style="clear:both"></div>'
)

choiceContainer.find("input").click( plotAccordingToChoices )

// Date of "Moratorium"
var moradate = (new Date(2011, 3-1, 17)).getTime()

var plot
var last_aggregation = "none"

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
function InitPlot( data, type ) {
    var startdate  = (new Date(2011,  1-1,  1)).getTime()
    var enddate    = (new Date(2011, 12-1, 31)).getTime()
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
    var ymin   = yaxis.min
    var ymax   = yaxis.max

/*
    var ymin
    var ymax
    if ( type != "cum" ) {
	ymin = -150.
	ymax =  200.
    } else {
	ymin = 0.
	ymax = 25000.
    }
    var deltay = ymax - ymin
*/

    // This time plot for real.
    plot = $.plot( plotContainer, data, {
        grid:   { markings: marking },
        legend: { noColumns: 2, position: "se", backgroundOpacity: .65 },
        xaxis:  { zoomRange: [ week, year ], panRange: [ startdate, enddate ], mode: "time" },
        yaxis:  { min: ymin, max: ymax, zoomRange: [ deltay/10., deltay*1.2 ] },
        pan:    { interactive: true },
        zoom:   { interactive: true, amount: 1.1 },
    })

    plotContainer.append('<div id="moratorium" style="position:absolute;white-space:nowrap;color:#666;font-size:smaller">AKW-Moratorium seit 17.3.2011</div>')

    // add zoom out button 
    $('<div class="button" style="position:absolute;cursor:pointer;right:10px;top:10px;font-size:smaller;background-color:#dddddd;padding:2px;opacity:.65">Ansicht zurücksetzen</div>').appendTo(plotContainer).click(function (e) {
        e.preventDefault()
        last_aggregation = "none"
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
    console.log( "plotAccordingToChoices() called." )

    var data = []
    
    // find data aggregation setting
    var adiv = $("#aggregationdiv")
    var aggregation = last_aggregation
    adiv.find("input:checked").each(function () {
        var key = $(this).attr("name")
        if ( key == "aggregation" ) {
            aggregation = $(this).attr("value")
        }
    })

    // use combination of country and year setting
    var cdiv = $("#countrydiv")
    var ydiv = $("#yeardiv")
    var elem = cdiv.find( "input:checked" )
    var col = 1
    while ( elem.length != 0 ) {
	var country = elem.attr( "id" )
	console.log( "country: " + country )
	ydiv.find( "input:checked" ).each( function () {
            var year = $(this).attr("name")
	    var name = "timeline_" + year + "_" + country + "_" + aggregation
	    if ( typeof eval(name) !== "undefined" ) {
		eval(name).color = col
                data.push( eval(name) )
		col++
	    }
	} )
	elem = elem.nextAll( "input:checked" )
    }

    if ( aggregation == last_aggregation || data.length == 0 ) return

    if ( aggregation == "cum" || last_aggregation == "cum" || last_aggregation == "none" ) {
        InitPlot( data, aggregation )
    } else {
        plot.setData( data )
        plot.setupGrid()
        plot.draw()
    }

    UpdateLabel()
    last_aggregation = aggregation
}

// from http://www.nczonline.net/blog/2009/07/28/the-best-way-to-load-external-javascript/
function loadScript(url, callback){

    var script = document.createElement("script")
    script.type = "text/javascript";

    if (script.readyState){  //IE
        script.onreadystatechange = function(){
            if (script.readyState == "loaded" ||
                    script.readyState == "complete"){
                script.onreadystatechange = null;
                callback();
            }
        };
    } else {  //Others
        script.onload = function(){
            callback();
        };
    }

    script.src = url;
    document.getElementsByTagName("head")[0].appendChild(script);
}

var count=0
var path=""
function cb() {
    count++
    if ( count == 7 ) plotAccordingToChoices()
}

loadScript( path+"fdata2005.js", cb )
loadScript( path+"fdata2006.js", cb )
loadScript( path+"fdata2007.js", cb )
loadScript( path+"fdata2008.js", cb )
loadScript( path+"fdata2009.js", cb )
loadScript( path+"fdata2010.js", cb )
loadScript( path+"fdata2011.js", cb )
