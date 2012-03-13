var test      = 0  // for local testing
var onlytotal = 1  // only show total sums since display of individual countries is still experimental
var logging   = 0  // must be off to prevent breakage of browsers without FireBug!!!


var choiceContainer = $("#choices");
var plotContainer   = $("#flotdiv");

function Log( msg ) {
    if ( logging ) {
	console.log( msg )
    }
}

choiceContainer.append(
    '' +
	'<div class="butgroup" id="yeardiv" style="float:left">Jahr:<br /></div>' +
	'<div class="butgroup" id="aggregationdiv" style="float:left">Aggregation:<br />' +
	'  <input id="1" name="aggregation" type="radio" value="1" /> <label for="1">tagesgenau</label><br />' +
	'  <input id="7" name="aggregation" type="radio" value="7" /> <label for="7">7-Tage-Durchschnitt</label><br />' +
	'  <input id="30" name="aggregation" type="radio" checked="checked" value="30" /> <label for="30">30-Tage-Durchschnitt</label><br />' +
	'  <input id="cum" name="aggregation" type="radio" value="cum" /> <label for="cum">kumulativ</label></br />' +
	'  <br />' +     // quick hack to fix display glitch
	'</div>' +
	( onlytotal ? '' : '<div class="butgroup" id="countrydiv" style="float:left">Länder:<br /></div>' ) +
	'<div class="butgroup" id="sourcediv" style="float:left">Quelle:<br /></div>' +
	'<div class="butgroup">Navigation:<br />' +
	'<span id="smallgray">Darstellung vergrößern oder verkleinern: Mausrad<br />' +
	'sichtbaren Ausschnitt verschieben: klicken und ziehen</span>' +
	'</div>' +
	'<div style="clear:both"></div>'
)
Log( "Appended controls to choiceContainer." )

var cdiv = $("#countrydiv")
var sdiv = $("#sourcediv")
var ydiv = $("#yeardiv")

// Date of "Moratorium"
var moradate = (new Date(2011, 3-1, 17)).getTime()

var alldata = []
var plot
var last_aggregation = "none"


function SetupInputs() {

    var countries = {}
    var sources   = {}
    var years     = {}
    for ( var i=0; i<alldata.length; i++ ) {
	var c  = alldata[i].country
	var y  = alldata[i].year
	var s  = alldata[i].source

	// Log( "SetupInputs(): " + c + " (" + y + "): " + s + ", agg: " + alldata[i].aggregation )

	countries[c] = c
	sources  [s] = s
	years    [y] = y
    }

/*
    # translation of country codes
    my %countries = ( 'AT' => 'Österreich',
		      'CH' => 'Schweiz',
		      'CZ' => 'Tschechien',
		      'DK' => 'Dänemark',
		      'FR' => 'Frankreich',
		      'LU' => 'Luxemburg',
		      'NL' => 'Niederlande',
		      'PL' => 'Polen',
		      'SE' => 'Schweden',
	);
*/


    // TODO:  is this sorted already or do I need to sort manually?
    if ( ! onlytotal ) {
	for ( var country in countries ) {
	    cdiv.append( '<input type="checkbox" id="' + country + '" name="' + country + '" /> '+
			 '<label for="' + country + '">' + country + '</label><br />' )
	}
    }
    for ( var source in sources ) {
	var label   = source
	var checked = ""
	if ( source == "flow" ) {
	    label   = "entsoe.net: 'physical flow'"
	    checked = ' checked="checked"'
	} else if ( source == "schedules" ) {
	    label = "entsoe.net: 'final schedules'"
	}
	sdiv.append( '<input type="checkbox" id="' + source + '"' + checked + ' name="' + source + '" /> '+
		     '<label for="' + source + '">' + label + '</label><br />' )
	Log( 'Adding source: ' + label )

    }

    // quick hack to fix display glitch
    sdiv.append( '<br />' )
    sdiv.append( '<br />' )

    for ( var year in years ) {
	var checked = ""
	if ( year >= 2010 ) {
	    checked = ' checked="checked"'
	}
	ydiv.append( '<input type="checkbox" id="' + year + '"' + checked + ' name="' + year + '" /> '+
		     '<label for="' + year + '">' + year + '</label><br />' )
	Log( 'Adding year: ' + year )
    }

    choiceContainer.find("input").click( plotAccordingToChoices )
}


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
        legend: { noColumns: 1, position: "se", backgroundOpacity: .65 },
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
    // Log( "plotAccordingToChoices() called." )

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
    Log( "Aggregation choice: " + aggregation )

    // find country, source and year settings
    var elem
    var countries = {}
    elem = cdiv.find( "input:checked" )
    while ( elem.length != 0 ) {
	var country = elem.attr( "id" )
	countries[ country ] = 1
	Log( "Country choice: " + country )
	elem = elem.nextAll( "input:checked" )
    }
    if ( onlytotal ) {
	countries[ 'total' ] = 1;
    }
    var sources = {}
    elem = sdiv.find( "input:checked" )
    while ( elem.length != 0 ) {
	var source = elem.attr( "id" )
	sources[ source ] = 1
	Log( "Source choice: " + source )
	elem = elem.nextAll( "input:checked" )
    }
    var years = {}
    elem = ydiv.find( "input:checked" )
    while ( elem.length != 0 ) {
	var year = elem.attr( "id" )
	years[ year ] = 1
	Log( "Year choice: " + year )
	elem = elem.nextAll( "input:checked" )
    }

    var col = 1
    for ( var year in years ) {
	for ( var country in countries ) {
	    for ( var source in sources ) {
		loop: for ( var i=0; i<alldata.length; i++ ) {
		    var dset = alldata[i]
		    if ( dset.country == country && dset.source == source && dset.year == year && dset.aggregation == aggregation ) {
			var clabel = country
			if ( country == "total" ) {
			    clabel = "Nettoexport"
			}
			dset.label = year + ": " + clabel + " (" + source + ")"
			dset.color = col++
			data.push( dset )
			break loop  // avoid duplicate display in case of duplicate datasets
//			Log( "matched: " + dset.country + " " + dset.source + " " + dset.year + " " + dset.aggregation )
		    } else {
//			Log( "unmatched: " + dset.country + " " + dset.source + " " + dset.year + " " + dset.aggregation )
		    }
		}
	    }
	}
    }

    Log( "Displaying " + data.length + " dataset(s)." )
    if ( data.length == 0 ) {
	return
    }

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

var pending = 0
var total   = 0
function cb() {
    pending--
    if ( !pending ) {
	Log( total + " file(s) loaded." )
	SetupInputs()
	plotAccordingToChoices()
    }
}

var path = "/stuff/strombilanz/"
if ( test ) {
    path = "../"
}
for ( var y = 2008; y <= 2012; y++ ) {
    pending += 3
    total += 3
    loadScript( path+"net"+y+".js", cb )
    loadScript( path+"flow"+y+".js", cb )
    loadScript( path+"sched"+y+".js", cb )
}
