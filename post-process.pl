#!/usr/bin/perl -w
#
# post process output of extract script, eg. adding moving average

#use diagnostics;
#use strict;

use POSIX qw(strftime);
use Time::Local;
use Getopt::Long;
my $year     = 0;
my $csv_file = '';
my $result   = GetOptions( "csvfile=s" => \$csv_file,
			   "year=i"    => \$year );

die "csvfile unset" if !$csv_file;
die "year unset"    if !$year;

my $fmt_short = '%Y-%m';
my $fmt_long  = '%F %T';
my %daily;          # timelines of day-precision data


#
# .csv reading
#
my $csv_ok = 0;
my $csv_debug = '';    # eg. 'LU'
my $csv_magic = 'Country_Exp,month,year,AT,BA,BE,BG,CH,CS,CZ,DE,DK,DK,EE,ES,FI,FR,GB,GR,HR,HU,IE,IT,LT,LU,LV,ME,MK,NI,NL,NO,PL,PT,RO,RS,SE,SI,SK,UA,AL,BY,MA,MD,RU,TR,UA,DK';
my @csv_tokens = split( /,/, $csv_magic );
my %csv_data;
my %csv_data_utime;
my %csv_neighbours;    # list of Germany's neighbours

open CSV, "<$csv_file"
    or die "Could not open $csv_file!";

while (<CSV>) {
    chomp;
    if ( /^Country_Exp/ ) {
        if ( /^$csv_magic/ ) {
            print "CSV format ok!\n";
	    $csv_ok = 1;
        } else {
            die "Bad CSV format!";
        }
        next;
    }
    next if ( !$csv_ok );

    for ( my $i = 3; $i < scalar @csv_tokens; $i++ ) {
	my $from = $csv_tokens[$i];
	if ( /^$from,(\d+),(\d+)/ ) {
	    my $month = $1 + 0; die "month $month out of range" if $month <= 0    || 13   <= $month;
	    my $year  = $2 + 0; die "year $year out of range"   if $year  <= 2000 || 2013 <= $year;
	    my @parts = split /,/;
	    for ( my $j = 3; $j < scalar @csv_tokens; $j++ ) {
		next if $j == $i;
		my $to  = $csv_tokens[$j];
		my $val = $parts[$j];
		$val = '' if ! defined $val;
		my $utime = timegm( 0, 0, 0, 16, $month-1, $year );   # ( $sec, $min, $hour, $mday, $mon, $year );
		if ( $val ne '' ) {
		    $csv_data{$from}{$to}{$year}{$month} = $val;
		    $csv_data_utime{$from}{$to}{$utime}  = $val;
		    print "$from->$to $year-$month $val\n" if ( $from eq 'DE' && $to eq $csv_debug || $from eq $csv_debug && $to eq 'DE' );
		    $csv_neighbours{$from} = 1 if ( $to   eq 'DE' );
		    $csv_neighbours{$to}   = 1 if ( $from eq 'DE' );
		}
	    }
	}
    }
}
close CSV;


#
# create interpolated timelines from .csv data
#
sub interpolate( $$$$ );
sub extrapolate( $$$$ );
my $lminimal = 0;
my $hminimal = ~0;
foreach my $country ( sort keys %csv_neighbours ) {
    (my $l1) = sort keys %{ $csv_data_utime{'DE'}{$country} };
    (my $l2) = sort keys %{ $csv_data_utime{$country}{'DE'} };
    (my $h1) = reverse sort keys %{ $csv_data_utime{'DE'}{$country} };
    (my $h2) = reverse sort keys %{ $csv_data_utime{$country}{'DE'} };
    my $l = ( $l1 < $l2 ? $l2 : $l1 ) + 12 * 3600;
    $lminimal = $l if $l > $lminimal;
    my $h = ( $h1 > $h2 ? $h2 : $h1 ) - 12 * 3600;
    $hminimal = $h if $h < $hminimal;
    print "DE <--> $country:  ", strftime( $fmt_short, gmtime( $l ) ), " ... ", strftime( $fmt_short, gmtime( $h ) ), "\n";
    for ( my $utime = $l; $utime <= $h; $utime += 24 * 3600 ) {
	$daily{"${country}_"}{$utime} = interpolate( 'DE', $country, $utime, 3600*24 ) - interpolate( $country, 'DE', $utime, 3600*24 );
    }
}

# interpolation of total_
print "Interpolate total_: ", strftime( $fmt_short, gmtime( $lminimal ) ), " ... ", strftime( $fmt_short, gmtime( $hminimal ) ), "\n";
for ( my $utime = $lminimal; $utime <= $hminimal; $utime += 24 * 3600 ) {
    $daily{"total_"}{$utime} = 0;
    foreach my $country ( sort keys %csv_neighbours ) {
	$daily{"total_"}{$utime} += interpolate( 'DE', $country, $utime, 3600*24 ) - interpolate( $country, 'DE', $utime, 3600*24 );
    }
}

# extrapolation of LU
$hminimal += 365 * 24 * 3600;
print "Extrapolate LU: ", strftime( $fmt_short, gmtime( $lminimal ) ), " ... ", strftime( $fmt_short, gmtime( $hminimal ) ), "\n";
for ( my $utime = $lminimal; $utime <= $hminimal; $utime += 24 * 3600 ) {
    $daily{'LU'}{$utime} = extrapolate( 'DE', 'LU', $utime, 3600*24 ) - extrapolate( 'LU', 'DE', $utime, 3600*24 );
}


#
# extract.pl data reading
#
my $lastutime = 0;
my @legend = ();
while (<>) {
    chomp;
    if ( /^#/ ) {
	@legend = split;
	shift @legend;
	next;
    }
    /^(\d{4})-(\d{2})-(\d{2})/ or next;
    my $year  = $1;
    my $month = $2;
    my $day   = $3;
    my $utime = timegm( 0, 0, 12, $day, $month-1, $year );   # ( $sec, $min, $hour, $mday, $mon, $year );

    # Skip data points which are not sequential.  This way it is possible to
    # combine the more up-to-date physical flow data with more accurate, but
    # delayed, final schedules.
    if ( $utime <= $lastutime ) {
        print "Skipping duplicate: $_";
        next;
    }

    die( "legend missing" ) if scalar @legend == 0;
    my @tokens = split;

    for ( my $i=1; $i < scalar @legend; $i++ ) {
	my $tag = $legend[$i];
	$daily{$tag}{$utime} = $tokens[$i];
    }
}

sub add_timeline ( $$$ );
sub avg_timeline ( $$ );
sub cum_timeline ( $ );
sub emit_timeline( $$$$$$ );

add_timeline( \%{ $daily{'total'} }, \%{ $daily{'LU'} }, 1. );

my $file;
open( $file, ">", "fdata$year.js" ) or die $!;  # data for flot
my $color=1;
foreach my $country ( sort keys %daily ) {
    my $year = 2011;
    emit_timeline( $daily{$country}, $year, $country, '1', $color, $file );
    my %tl = avg_timeline( $daily{$country}, 7 );
    emit_timeline( \%tl, $year, $country, '7', $color, $file );
    %tl = avg_timeline( $daily{$country}, 30 );
    emit_timeline( \%tl, $year, $country, '30', $color, $file );
    %tl = cum_timeline( $daily{$country} );
    emit_timeline( \%tl, $year, $country, 'cum', $color, $file );
    $color++;
}
close( $file );

exit 0;


# Add one timeline to another: $tl += $factor * $tl2
sub BinSearch( $@ );
sub add_timeline( $$$ ) {
    my $tl     = shift;  # reference to base timeline
    my $tl2    = shift;  # addition timeline
    my $factor = shift;  # scale factor to be applied to tl2

    foreach my $utime ( sort keys %{ $tl } ) {
	if ( ! exists $tl2->{$utime} ) {
	    my @keys = sort keys %{ $tl2 };
	    my $ret = BinSearch( $utime, @keys );
	    die( "tl2 range insufficient: " . strftime( $fmt_long, gmtime( $utime ) ) . "\n"
		 ." >= " . strftime( $fmt_long, gmtime( $keys[$ret] ) ) . "\n"
		 ." < "  . ( $ret > 0 ? strftime( $fmt_long, gmtime( $keys[$ret-1] ) ) : 'none' ) . "\n" );
	}
	$tl->{$utime} += $factor * $tl2->{$utime};
    }
}

# Compute sliding average over $int days
sub avg_timeline( $$ ) {
    my $tl  = shift;  # reference to timeline
    my $int = shift;  # integration time in days

    my %ret;
    my %backlog;
    foreach my $utime ( sort keys %{ $tl } ) {
	$backlog{$utime} = $tl->{$utime};

	my $sum = 0.;
	my $n   = 0;
	foreach my $t ( keys %backlog ) {
	    if ( $utime - $t > 3600 * 24 * $int && $int > 0 ) {
		delete $backlog{$t};
		next;
	    }
	    $sum += $backlog{$t};
	    $n++;
	}

	$ret{$utime} = $sum/$n unless $n < $int;
    }
    return %ret;
}

# Compute yearly summations
sub cum_timeline( $ ) {
    my $tl  = shift;  # reference to timeline

    my %ret;
    my $sum      = 0.;
    my $lastyear = 0;
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$sum = 0. if $year != $lastyear;
	$lastyear = $year;
	$sum += $tl->{$utime};
	$ret{$utime} = $sum;
    }
    return %ret;
}

# write timeline to javascript file
sub emit_timeline( $$$$$$ ) {
    my $tl    = shift;   # reference to timeline
    my $y     = shift;   # year
    my $tag   = shift;   # id-tag, eg. "FR" or "total"
    my $agg   = shift;   # aggregation, eg. 1, 7, 30 or "cum"
    my $color = shift;
    my $file  = shift;

    print "Emitting $y $tag $agg (full size: ", scalar keys %{ $tl }, ", ";

    print $file "var timeline_${year}_${tag}_${agg} = {\n";
    # disable label to disable legend
    print $file "\tlabel: \"$tag\",\n";
    print $file "\tcolor: $color,\n";
    print $file "\tdata: [\n";

    my $linecount = 0;
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;
	next if $year != $y;

	# Normalized javascript time.  Year is arbitrary because we want to
	# display all years on top of each other Jan-Dec.
	my $jtime = timegm( 0, 0, 12, $mday, $month, 1984 );   # ( $sec, $min, $hour, $mday, $mon, $year );
	$jtime *= 1000.;  # javascript time is in milliseconds

	print $file "\t\t[$jtime, " . $tl->{$utime} . "],\n";
	$linecount++;
    }
    print $file "\t]\n";
    print $file "}\n";

    print $file "{\n";
    print $file "\tvar ydiv = \$(\"#yeardiv\")\n";
    print $file "\tif ( ydiv.find('#$y').length == 0 ) {\n";
    print $file "\t\tydiv.append( '<input type=\"checkbox\" id=\"$y\" checked=\"checked\" name=\"$y\" /> '+\n";
    print $file "\t\t\t'<label for=\"$y\">$y</label><br />' )\n";
    print $file "\t}\n";
    print $file "}\n";


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

    my $translation;
    if ( exists $countries{$tag} ) {
	$translation = $countries{$tag};
    } else {
	$translation = $tag;
    }

    print $file "{\n";
    print $file "\tvar cdiv = \$(\"#countrydiv\")\n";
    print $file "\tif ( cdiv.find('#$tag').length == 0 ) {\n";
    print $file "\t\tcdiv.append( '<input type=\"checkbox\" id=\"$tag\" name=\"$tag\" /> '+\n";  # checked=\"checked\" 
    print $file "\t\t\t'<label for=\"$tag\">$translation</label><br />' )\n";
    print $file "\t}\n";
    print $file "}\n";

    print "lines written: $linecount)\n";
}


# Return first value which is greater or equal to $val.
sub BinSearch( $@ ) {
    my $val    = shift;
    my @a      = @_;
    my $minpos = 0;             # smaller than $val
    my $maxpos = scalar @a -1;  # greater or equal to $val

    # check out of range
    if ( $val < $a[$minpos] || $a[$maxpos] < $val ) {
	return -1;
    }

    while ( $maxpos - $minpos > 1 ) {
	my $pos = int( ($maxpos+$minpos)/2 );
	if ( $a[$pos] < $val ) {
	    $minpos = $pos;
	} else {
	    $maxpos = $pos;
	}
    }
    return $maxpos;
}

# Interpolate between .csv data points.
sub interpolate( $$$$ ) {
    my $from     = shift;
    my $to       = shift;
    my $utime    = shift;  # unixtime
    my $integral = shift;  # integration time

    my $data_utime = \%{ $csv_data_utime{$from}{$to} };
    my @autime     = sort keys %{ $data_utime };
    
    my $ige = BinSearch( $utime, @autime );
    die "interpolate: out of range: $from $to ", strftime( $fmt_long, gmtime( $utime ) ) , " $integral" if $ige == -1;

    my $ilo    = $ige-1;
    my $getime = $autime[$ige];
    my $lotime = $autime[$ilo];
    my $geval  = $data_utime->{$getime};
    my $loval  = $data_utime->{$lotime};
    my $val    = $loval + ($utime-$lotime)*($geval-$loval)/($getime-$lotime);
    return $val * $integral / 30 / 24 / 3600;
}

# Use previous years' data to extrapolate, if interpolation is not possible.
sub extrapolate( $$$$ ) {
    my $from     = shift;
    my $to       = shift;
    my $utime    = shift;  # unixtime
    my $integral = shift;  # integration time

    my $data_utime = \%{ $csv_data_utime{$from}{$to} };
    my $data       = \%{ $csv_data{$from}{$to} };
    my @autime     = sort keys %{ $data_utime };
    
    my $ige = BinSearch( $utime, @autime );
    return interpolate( $from, $to, $utime, $integral ) if ( $ige != -1 );

    (my $sec, my $min, my $hour, my $day, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
    $month++;
    $year += 1900;
    
    # data point before $utime
    my $yearbefore  = $year;
    my $monthbefore = ( $month - ( $day < 16 ) );
    if ( $monthbefore == 0 ) {
        $monthbefore = 12;
        $yearbefore--;
    }
    # data point after $utime
    my $yearafter  = $year;
    my $monthafter = ( $month + ( $day >= 16 ) );
    if ( $monthafter == 13 ) {
        $monthafter = 1;
        $yearafter++;
    }

    my $nbef = 0;
    my $sumbef = 0.;
    for my $y ( reverse sort keys %{ $data } ) {
	next if ! defined $data->{$y}{$monthbefore};
	$sumbef += $data->{$y}{$monthbefore};
	$nbef++;
	last if $nbef == 4;
    }
    die( "insufficient data for extrapolation" ) if $nbef < 4;
    my $avgbef = $sumbef / $nbef;
    
    my $naft = 0;
    my $sumaft = 0.;
    for my $y ( reverse sort keys %{ $data } ) {
	next if ! defined $data->{$y}{$monthafter};
	$sumaft += $data->{$y}{$monthafter};
	$naft++;
	last if $naft == 4;
    }
    die( "insufficient data for extrapolation" ) if $naft < 4;
    my $avgaft = $sumaft / $naft;
    
    my $ubefore = timegm( 0, 0, 0, 16, $monthbefore -1, $yearbefore );
    my $uafter  = timegm( 0, 0, 0, 16, $monthafter  -1, $yearafter  );
    my $d       = $uafter - $ubefore;
    my $val     = $avgbef + ($utime-$ubefore)*($avgaft-$avgbef)/($uafter-$ubefore);
    return $val * $integral / 30. / 24. / 3600.;
}
