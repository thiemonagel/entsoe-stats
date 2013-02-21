/*
 * tested and working:  Firefox (Linux, Android 2.3), Chrome (Linux), Android 2.3 Browser, IE 8
 * to be tested:  Safari (MacOS, iOS), IE 9
 */

var onlytotal = 1  // only show total sums since display of individual countries is still experimental


function Log( msg ) {
    if ( typeof console != 'undefined' ) {
	console.log( msg )
    }
}


/*! LAB.js (LABjs :: Loading And Blocking JavaScript)
    v2.0.3 (c) Kyle Simpson
    MIT License
    http://labjs.com/
*/
(function(o){var K=o.$LAB,y="UseLocalXHR",z="AlwaysPreserveOrder",u="AllowDuplicates",A="CacheBust",B="BasePath",C=/^[^?#]*\//.exec(location.href)[0],D=/^\w+\:\/\/\/?[^\/]+/.exec(C)[0],i=document.head||document.getElementsByTagName("head"),L=(o.opera&&Object.prototype.toString.call(o.opera)=="[object Opera]")||("MozAppearance"in document.documentElement.style),q=document.createElement("script"),E=typeof q.preload=="boolean",r=E||(q.readyState&&q.readyState=="uninitialized"),F=!r&&q.async===true,M=!r&&!F&&!L;function G(a){return Object.prototype.toString.call(a)=="[object Function]"}function H(a){return Object.prototype.toString.call(a)=="[object Array]"}function N(a,c){var b=/^\w+\:\/\//;if(/^\/\/\/?/.test(a)){a=location.protocol+a}else if(!b.test(a)&&a.charAt(0)!="/"){a=(c||"")+a}return b.test(a)?a:((a.charAt(0)=="/"?D:C)+a)}function s(a,c){for(var b in a){if(a.hasOwnProperty(b)){c[b]=a[b]}}return c}function O(a){var c=false;for(var b=0;b<a.scripts.length;b++){if(a.scripts[b].ready&&a.scripts[b].exec_trigger){c=true;a.scripts[b].exec_trigger();a.scripts[b].exec_trigger=null}}return c}function t(a,c,b,d){a.onload=a.onreadystatechange=function(){if((a.readyState&&a.readyState!="complete"&&a.readyState!="loaded")||c[b])return;a.onload=a.onreadystatechange=null;d()}}function I(a){a.ready=a.finished=true;for(var c=0;c<a.finished_listeners.length;c++){a.finished_listeners[c]()}a.ready_listeners=[];a.finished_listeners=[]}function P(d,f,e,g,h){setTimeout(function(){var a,c=f.real_src,b;if("item"in i){if(!i[0]){setTimeout(arguments.callee,25);return}i=i[0]}a=document.createElement("script");if(f.type)a.type=f.type;if(f.charset)a.charset=f.charset;if(h){if(r){e.elem=a;if(E){a.preload=true;a.onpreload=g}else{a.onreadystatechange=function(){if(a.readyState=="loaded")g()}}a.src=c}else if(h&&c.indexOf(D)==0&&d[y]){b=new XMLHttpRequest();b.onreadystatechange=function(){if(b.readyState==4){b.onreadystatechange=function(){};e.text=b.responseText+"\n//@ sourceURL="+c;g()}};b.open("GET",c);b.send()}else{a.type="text/cache-script";t(a,e,"ready",function(){i.removeChild(a);g()});a.src=c;i.insertBefore(a,i.firstChild)}}else if(F){a.async=false;t(a,e,"finished",g);a.src=c;i.insertBefore(a,i.firstChild)}else{t(a,e,"finished",g);a.src=c;i.insertBefore(a,i.firstChild)}},0)}function J(){var l={},Q=r||M,n=[],p={},m;l[y]=true;l[z]=false;l[u]=false;l[A]=false;l[B]="";function R(a,c,b){var d;function f(){if(d!=null){d=null;I(b)}}if(p[c.src].finished)return;if(!a[u])p[c.src].finished=true;d=b.elem||document.createElement("script");if(c.type)d.type=c.type;if(c.charset)d.charset=c.charset;t(d,b,"finished",f);if(b.elem){b.elem=null}else if(b.text){d.onload=d.onreadystatechange=null;d.text=b.text}else{d.src=c.real_src}i.insertBefore(d,i.firstChild);if(b.text){f()}}function S(c,b,d,f){var e,g,h=function(){b.ready_cb(b,function(){R(c,b,e)})},j=function(){b.finished_cb(b,d)};b.src=N(b.src,c[B]);b.real_src=b.src+(c[A]?((/\?.*$/.test(b.src)?"&_":"?_")+~~(Math.random()*1E9)+"="):"");if(!p[b.src])p[b.src]={items:[],finished:false};g=p[b.src].items;if(c[u]||g.length==0){e=g[g.length]={ready:false,finished:false,ready_listeners:[h],finished_listeners:[j]};P(c,b,e,((f)?function(){e.ready=true;for(var a=0;a<e.ready_listeners.length;a++){e.ready_listeners[a]()}e.ready_listeners=[]}:function(){I(e)}),f)}else{e=g[0];if(e.finished){j()}else{e.finished_listeners.push(j)}}}function v(){var e,g=s(l,{}),h=[],j=0,w=false,k;function T(a,c){a.ready=true;a.exec_trigger=c;x()}function U(a,c){a.ready=a.finished=true;a.exec_trigger=null;for(var b=0;b<c.scripts.length;b++){if(!c.scripts[b].finished)return}c.finished=true;x()}function x(){while(j<h.length){if(G(h[j])){try{h[j++]()}catch(err){}continue}else if(!h[j].finished){if(O(h[j]))continue;break}j++}if(j==h.length){w=false;k=false}}function V(){if(!k||!k.scripts){h.push(k={scripts:[],finished:true})}}e={script:function(){for(var f=0;f<arguments.length;f++){(function(a,c){var b;if(!H(a)){c=[a]}for(var d=0;d<c.length;d++){V();a=c[d];if(G(a))a=a();if(!a)continue;if(H(a)){b=[].slice.call(a);b.unshift(d,1);[].splice.apply(c,b);d--;continue}if(typeof a=="string")a={src:a};a=s(a,{ready:false,ready_cb:T,finished:false,finished_cb:U});k.finished=false;k.scripts.push(a);S(g,a,k,(Q&&w));w=true;if(g[z])e.wait()}})(arguments[f],arguments[f])}return e},wait:function(){if(arguments.length>0){for(var a=0;a<arguments.length;a++){h.push(arguments[a])}k=h[h.length-1]}else k=false;x();return e}};return{script:e.script,wait:e.wait,setOptions:function(a){s(a,g);return e}}}m={setGlobalDefaults:function(a){s(a,l);return m},setOptions:function(){return v().setOptions.apply(null,arguments)},script:function(){return v().script.apply(null,arguments)},wait:function(){return v().wait.apply(null,arguments)},queueScript:function(){n[n.length]={type:"script",args:[].slice.call(arguments)};return m},queueWait:function(){n[n.length]={type:"wait",args:[].slice.call(arguments)};return m},runQueue:function(){var a=m,c=n.length,b=c,d;for(;--b>=0;){d=n.shift();a=a[d.type].apply(null,d.args)}return a},noConflict:function(){o.$LAB=K;return m},sandbox:function(){return J()}};return m}o.$LAB=J();(function(a,c,b){if(document.readyState==null&&document[a]){document.readyState="loading";document[a](c,b=function(){document.removeEventListener(c,b,false);document.readyState="complete"},false)}})("addEventListener","DOMContentLoaded")})(this);


//
// Load code and data.
//

// In webkit-based browsers, callback for .css files doesn't work.  Therefore
// .css files are not included in the "pending" count.
function loadCSS( url ) {

    Log( 'Requesting CSS: ' + url )

    var file = document.createElement( 'link' )
    file.rel   = 'stylesheet'
    file.type  = 'text/css'
    file.media = 'all'
    file.href  = url

    document.getElementsByTagName('head')[0].appendChild(file)
}


// determine full URL of stromscripts.js so that the directory
// part can be used as a prefix to fetch the data files
var prefix
var scripts = document.getElementsByTagName( 'script' )
for ( var i = 0; i < scripts.length; i++ ) {
  var s = scripts.item(i)
  if ( s.src && s.src.match( /stromscripts\.js$/ ) )
      prefix = s.src.match( /^.*\// )
}
Log( "Determined prefix: " + prefix )


// load css
loadCSS( prefix+'stromstyles.css' )

// load data files
for ( var y = 2008; y <= 2013; y++ ) {
//for ( var y = 2012; y <= 2012; y++ ) {
    $LAB.queueScript( prefix + 'eu'    + y + '.js' )
        .queueScript( prefix + 'flow'  + y + '.js' )
        .queueScript( prefix + 'sched' + y + '.js' )
}

// load jQuery/flot
$LAB.queueScript( prefix + 'flot/jquery.min.js' )
    .queueWait()
    .queueScript( prefix + 'flot/jquery.flot.min.js' )
    .queueWait()
    .queueScript( prefix + 'flot/jquery.flot.resize.min.js' )
    .queueScript( prefix + 'flot/jquery.flot.navigate.min.js' )
    .queueWait( function(){
        Step2()
    })

$LAB.runQueue()


// load excanvas for IE < 9
function Step2() {
    lab = $LAB.sandbox()

    if ( jQuery.browser.msie == true && jQuery.browser.version < 9 ) {
        Log( 'IE<9 detected.  Loading excanvas.' )
        lab.queueScript( prefix + 'flot/excanvas.min.js' )
    }

    lab.runQueue()
        .wait( function(){
            Setup()
            plotAccordingToChoices()
        })
}


// Date of "Moratorium"
var moradate = (new Date(2011, 3-1, 17)).getTime()

var alldata = []
var plot
var last_aggregation = 'none'


var plotContainer
var cdiv
var sdiv
var ydiv
function Setup() {

    Log( "Starting setup." )

    //
    // write some HTML
    //
    plotContainer       = $("#flotdiv")
    var choiceContainer = $("#choicesdiv")
    
    choiceContainer.append(
        '' +
	    '<div class="butgroup" id="yeardiv" style="width:15%">Jahr:<br /></div>' +
	    '<div class="butgroup" id="aggregationdiv">Aggregation:<br />' +
	    '  <input id="1" name="aggregation" type="radio" value="1" /> <label for="1">tagesgenau</label><br />' +
	    '  <input id="7" name="aggregation" type="radio" value="7" /> <label for="7">7-Tage-Durchschnitt</label><br />' +
	    '  <input id="30" name="aggregation" type="radio" checked="checked" value="30" /> <label for="30">30-Tage-Durchschnitt</label><br />' +
	    '  <input id="cum" name="aggregation" type="radio" value="cum" /> <label for="cum">kumulativ</label></br />' +
	    '</div>' +
	    ( onlytotal ? '' : '<div class="butgroup" id="countrydiv" style="float:left">Länder:<br /></div>' ) +
	    '<div class="butgroup" id="sourcediv" style="width:30%">Quelle:<br /></div>' +
	    '<div class="butgroup" style="width:30%">Navigation:<br />' +
	    '  <span id="smallgray">Darstellung vergrößern oder verkleinern: Mausrad<br />' +
	    '  sichtbaren Ausschnitt verschieben: klicken und ziehen</span>' +
	    '</div>' +
	    '<div style="clear:both"></div>'
    )


    cdiv = $("#countrydiv")
    sdiv = $("#sourcediv")
    ydiv = $("#yeardiv")

    Log( 'Preparing ' + alldata.length + ' data set(s):' )

    var countries = {}
    var sources   = new Array()
    var years     = new Array()
    for ( var i=0; i<alldata.length; i++ ) {
	var c  = alldata[i].country
	var y  = alldata[i].year
	var s  = alldata[i].source

//	Log( "  data set: " + c + " (" + y + "): " + s + ", agg: " + alldata[i].aggregation )

	countries[c] = c
        
        // don't use sources.indexOf() because it breaks IE 8 (yuck!)
        if ( $.inArray( s, sources ) < 0 )
            sources.push(s)

        if ( $.inArray( y, years ) < 0 )
            years.push(y)
    }
    sources.sort()
    years.sort()

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


    // TODO:  needs to be sorted manually
    if ( ! onlytotal ) {
	for ( var country in countries ) {
	    cdiv.append( '<input type="checkbox" id="' + country + '" name="' + country + '" /> '+
			 '<label for="' + country + '">' + country + '</label><br />' )
	}
    }
    
    Log( 'Found ' + sources.length + ' different data source(s):' )
    for ( var i=0; i<sources.length; i++ ) {
        var source  = sources[i]
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
	Log( '  adding source: ' + label )

    }

    Log( 'Found data from ' + years.length + ' year(s):' )
    for ( var i=0; i<years.length; i++ ) {
        var year = years[i]
	var checked = ""
	if ( year >= 2010 ) {
	    checked = ' checked="checked"'
	}
	ydiv.append( '<input type="checkbox" id="' + year + '"' + checked + ' name="' + year + '" /> '+
		     '<label for="' + year + '">' + year + '</label><br />' )
	Log( '  adding year: ' + year )
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

    Log( 'Starting InitPlot.' )

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

    Log( 'Done InitPlot.' )
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
