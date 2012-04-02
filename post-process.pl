#!/usr/bin/perl -w
#
# Post process output of extract script, eg. of adding moving average.
#
# Input files must be specified in order of priority:  most important first.
# Subsequent files will only be used for data points that are missing from
# earlier files.
#
# Requires debian package: libclone-perl

#use diagnostics;
use strict;

use Clone qw(clone);
use Getopt::Long;
use POSIX qw(strftime);
use Time::Local;

my $dbg         = 1;
my $baseunit    = 1e9/24.;  # GWh/day (unit of input data)
my $dispunit    = 1e9;      # GW sustained (unit of output data)
my $dispyear    = 2011;     # no leap year

my $year_first  = 2005;
my $year_last   = 2012;
my $output_year = 1;
my $output_csv  = 0;
my $output_stem = '';
my $content     = '';
my $csv_file    = '';
my $result      = GetOptions( "content=s" => \$content,         # data source
			      "csvfile=s" => \$csv_file,
			      "outstem=s" => \$output_stem,
			      "outcsv"    => \$output_csv,      # output csv data?
			      "outyear=i" => \$output_year );   # 1: magic value for "all years"

die "csvfile unset" unless $csv_file;
die "outstem unset" unless $output_stem;
die "year unset"    unless $output_year;


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
#            print "CSV format ok!\n";
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
		    $val *= $baseunit / $dispunit;
		    # ignore 29th Feb in leap years
		    if ( $month == 2 && $year % 4 == 0 && ( $year % 100 != 0 || $year % 400 == 0 ) ) {
			$val *= 28 / 29.;
		    }
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

for ( my $year = 2006; $year < 2012; $year++ ) {
    my $sum = 0.;
    for ( my $month = 1; $month <= 12; $month++ ) {
	foreach my $country ( sort keys %csv_neighbours ) {
	    $sum += $csv_data{'DE'}{$country}{$year}{$month};
	    $sum -= $csv_data{$country}{'DE'}{$year}{$month};
	}
    }
    printf "CSV yearsum %i: %f (%f GWh)\n", $year, $sum, $sum * $dispunit/$baseunit;
}


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
    print "entsoe.eu: DE <--> $country:  ", strftime( $fmt_short, gmtime( $l ) ), " ... ", strftime( $fmt_short, gmtime( $h ) ), "\n";
    for ( my $utime = $l; $utime <= $h; $utime += 24 * 3600 ) {
	$daily{"${country}_CSV"}{$utime} = interpolate( 'DE', $country, $utime, 3600*24 ) - interpolate( $country, 'DE', $utime, 3600*24 );
    }
}

# interpolation of total_CSV
print "Interpolate total_CSV: ", strftime( $fmt_short, gmtime( $lminimal ) ), " ... ", strftime( $fmt_short, gmtime( $hminimal ) ), "\n";
for ( my $utime = $lminimal; $utime <= $hminimal; $utime += 24 * 3600 ) {
    $daily{'total_CSV'}{$utime} = 0;
    foreach my $country ( sort keys %csv_neighbours ) {
	$daily{'total_CSV'}{$utime} += interpolate( 'DE', $country, $utime, 3600*24 ) - interpolate( $country, 'DE', $utime, 3600*24 );
    }
}

# extrapolation of LU
$hminimal += 365 * 24 * 3600;
print "Extrapolate LU: ", strftime( $fmt_short, gmtime( $lminimal ) ), " ... ", strftime( $fmt_short, gmtime( $hminimal ) ), "\n";
for ( my $utime = $lminimal; $utime <= $hminimal; $utime += 24 * 3600 ) {
    $daily{'LU_CSV'}{$utime} = extrapolate( 'DE', 'LU', $utime, 3600*24 ) - extrapolate( 'LU', 'DE', $utime, 3600*24 );
}


#
# extract.pl data reading
#
my $filecount = 0;
if ( @ARGV ) {
    my @legend = ();
    print "Reading XML data:\n";
    my $lastfile = '';
    while (<>) {
	die "content unset" if !$content;
	
	if ( $lastfile ne $ARGV ) {
	    print "$filecount data points.\n" if $lastfile;
	    print "$ARGV: ";
	    $filecount = 0;
	    $lastfile = $ARGV;
	}
	
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
	
	# ignore 29th Feb in leap years
	next if ( $month == 2 && $day == 29 );
	
	my $utime = timegm( 0, 0, 12, $day, $month-1, $year );   # ( $sec, $min, $hour, $mday, $mon, $year );
	
	die( "legend missing" ) if scalar @legend == 0;
	my @tokens = split;
	
	for ( my $i=1; $i < scalar @legend; $i++ ) {
	    my $tag = $legend[$i];
	    my $val = $tokens[$i];
	    
	    # skip missing values
	    next if $val eq "N/A";
	    
	    # skip if value has already been read from an earlier file
	    next if defined $daily{$tag}{$utime};
	    
	    $val *= $baseunit / $dispunit;
	    $daily{$tag}{$utime} = $val;
	    $filecount++;
	}
    }
    print "$filecount data points.\n" if $lastfile;
    print "\n";
}


sub add_timeline       ( $$$ );
sub avg_timeline_years ( $$% );
sub avg_timeline_years2( $$% );
sub cmp_timeline       ( $$ );
sub avg_timeline       ( $$ );
sub cum_timeline       ( $ );
sub emit_timeline      ( $$$$$ );

if ( $filecount > 0 ) {
    print "add_timeline: total += LU\n";
    add_timeline( $daily{'total'}, $daily{'LU_CSV'}, 1. );
}
#avg_timeline_years2( 'total', 'totalavg', ( 2009 => 1, 2010 => 1 ) );
#$daily{'delta'} = clone( $daily{'total'} );
#print "add_timeline: delta -= totalavg\n";
#add_timeline( $daily{'delta'}, $daily{'totalavg'}, -1. );

foreach my $tag ( sort keys %daily ) {
    next if $tag =~ /_$/;
    cmp_timeline( $tag, "${tag}_" );
}

# write data for flot
for ( my $year = $year_first; $year <= $year_last; $year++ ) {
    next if $year != $output_year && $output_year != 1;

    my $file;      # only "total" summary
    my $filefull;  # full data
    open( $file,     ">", "$output_stem${year}.js"     ) or die $!;
    open( $filefull, ">", "$output_stem${year}full.js" ) or die $!;
    print "Writing to files: $output_stem${year}.js and $output_stem${year}full.js\n";
    foreach my $tag ( sort keys %daily ) {
        print "tag: $tag\n";
        foreach my $f ( ( $filefull, $file ) ) {
            emit_timeline( $daily{$tag}, $year, $tag, '1', $f );
            my %tl = avg_timeline( $daily{$tag}, 7 );
            emit_timeline( \%tl, $year, $tag, '7', $f );
            %tl = avg_timeline( $daily{$tag}, 30 );
            emit_timeline( \%tl, $year, $tag, '30', $f );
            %tl = cum_timeline( $daily{$tag} );
            emit_timeline( \%tl, $year, $tag, 'cum', $f );

            # skip everything except total sum for second file
            last if $tag !~ /^total/;
        }
    }

    print $file     "if ( typeof console != 'undefined' )\n";
    print $file     "\tconsole.log( 'Self-log: loaded $output_stem${year}.js' )\n";
    print $filefull "if ( typeof console != 'undefined' )\n";
    print $filefull "\tconsole.log( 'Self-log: loaded $output_stem${year}full.js' )\n";
    close( $file     );
    close( $filefull );
}

exit 0;


# Add one timeline to another: $tl += $factor * $tl2
# Time points of $tl2 must be the same or a superset of $tl.
sub BinSearch( $$ );
sub add_timeline( $$$ ) {
    my $tl     = shift;  # reference to base timeline
    my $tl2    = shift;  # reference to addition timeline
    my $factor = shift;  # scale factor to be applied to tl2

    foreach my $utime ( sort keys %{ $tl } ) {
	if ( ! exists $tl2->{$utime} ) {
	    my @keys = sort keys %{ $tl2 };
	    my $ret = BinSearch( $utime, \@keys );
	    die( "add_timeline(): tl2 range insufficient: " . strftime( $fmt_long, gmtime( $utime ) ) . "\n"
		 ." >= " . strftime( $fmt_long, gmtime( $keys[$ret] ) ) . "\n"
		 ." < "  . ( $ret > 0 ? strftime( $fmt_long, gmtime( $keys[$ret-1] ) ) : 'none' ) . "\n" );
	}
	$tl->{$utime} += $factor * $tl2->{$utime};
    }
}

sub avg_timeline_years( $$% ) {
    my $tag      = shift;  # tag of timeline to average
    my $fakeyear = shift;  # fake year to use for averaged data
    my %years    = @_;     # years over which is averaged

    my $n        = scalar keys %years;
    my $tl       = $daily{$tag};  # reference to timeline
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;
	next if ! exists $years{$year};
	$year = $fakeyear;
	my $fakeutime = timegm( $sec, $min, $hour, $mday, $month, $year );
	$tl->{$fakeutime} = 0. if ! exists $tl->{$fakeutime};
	$tl->{$fakeutime} += $tl->{$utime} / $n;
    }
}

sub avg_timeline_years2( $$% ) {
    my $tag1     = shift;  # tag of timeline to average
    my $tag2     = shift;  # new tag for averaged timeline
    my %years    = @_;     # years over which is averaged

    my $n        = scalar keys %years;
    my $tl       = $daily{$tag1};  # reference to timeline

    my %outyears;  # years for which average should be written
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;
	$outyears{$year} = 1;
    }
    
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;
	next if ! exists $years{$year};
	foreach my $y ( sort keys %outyears ) {
	    $year = $y;
	    my $fakeutime = timegm( $sec, $min, $hour, $mday, $month, $year );
	    $daily{$tag2}{$fakeutime} = 0. if ! exists $daily{$tag2}{$fakeutime};
	    $daily{$tag2}{$fakeutime} += $tl->{$utime} / $n;
	}
    }
}

# Compare two timelines
sub cmp_timeline( $$ ) {
    my $tag1 = shift;
    my $tag2 = shift;

    return if ! exists $daily{$tag1};
    return if ! exists $daily{$tag2};

    print "Comparing $tag1 and $tag2\n";
    my $tl   = $daily{$tag1};  # reference to 1st timeline
    my $tl2  = $daily{$tag2};  # reference to 2nd timeline

    my $sum      = 0.;
    my $sum2     = 0.;
    my $lastyear = 0;
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $mday, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;

	if ( $year != $lastyear && $lastyear != 0 || ! exists $tl2->{$utime} ) {
	    my $delta   = $sum2-$sum;
	    my $percent = $delta * 2. * 100. / ($sum+$sum2);
	    printf "\t$lastyear delta: %9.3f (approx. %7.1f%%)", $delta, $percent;
	    $sum  = 0.;
	    $sum2 = 0.;
	    if ( ! exists $tl2->{$utime} ) {
		print " (last data point: ", strftime( $fmt_long, gmtime( $utime ) ), ")\n";
		return;
	    }
	    print "\n";
	}
	$lastyear = $year;

	$sum  += $tl->{$utime};
	$sum2 += $tl2->{$utime};
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
sub emit_timeline( $$$$$ ) {
    my $tl    = shift;   # reference to timeline
    my $y     = shift;   # year
    my $tag   = shift;   # id-tag, eg. "FR" or "total"
    my $agg   = shift;   # aggregation, eg. 1, 7, 30 or "cum"
    my $file  = shift;

#    print "Emitting $y $tag $agg (full size: ", scalar keys %{ $tl }, ", ";

    my $data_source = $content;
    if ( $tag =~ /(.*)_CSV$/ ) {
	return unless $output_csv;
	$data_source = 'entsoe.eu';
	$tag = $1;
    }

    print $file "alldata.push( {\n";
    # disable label to disable legend
    print $file "\tsource:       \"$data_source\",\n";
    print $file "\tyear:         \"$y\",\n";
    print $file "\tcountry:      \"$tag\",\n";
    print $file "\taggregation:  \"$agg\",\n";
    print $file "\tdata: [\n";

    my $linecount = 0;
    foreach my $utime ( sort keys %{ $tl } ) {
	(my $sec, my $min, my $hour, my $day, my $month, my $year, my $wday, my $yday, my $isdst) = gmtime( $utime );
	$year += 1900;
	next if $year != $y;

	# ignore 29th Feb in leap years
	next if ( $month+1 == 2 && $day == 29 );

	# Normalized javascript time.  Year is arbitrary because we want to
	# display all years on top of each other Jan-Dec.
	my $jtime = timegm( 0, 0, 12, $day, $month, $dispyear );   # ( $sec, $min, $hour, $mday, $mon, $year );
	$jtime *= 1000.;  # javascript time is in milliseconds

	print $file "\t\t[$jtime, " . $tl->{$utime} . "],";
	print $file " // ", strftime( $fmt_long, gmtime( $utime ) ) if $dbg;
	print $file "\n";
	$linecount++;
    }
    print $file "\t]\n";
    print $file "} )\n";

#    print "lines written: $linecount)\n";
}


# Return first value which is greater or equal to $val.
sub BinSearch( $$ ) {
    my $val    = shift;   # needle
    my $a      = shift;   # haystack: sorted array
    my $minpos = 0;                # smaller than $val
    my $maxpos = scalar @{$a} -1;  # greater or equal to $val

    # check out of range
    if ( $maxpos < 0 || $val < $a->[$minpos] || $a->[$maxpos] < $val ) {
	return -1;
    }

    while ( $maxpos - $minpos > 1 ) {
	my $pos = int( ($maxpos+$minpos)/2 );
	if ( $a->[$pos] < $val ) {
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
    
    my $ige = BinSearch( $utime, \@autime );
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
    
    my $ige = BinSearch( $utime, \@autime );
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
