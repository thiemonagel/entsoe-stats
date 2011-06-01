#!/usr/bin/perl -w
#
# post process output of extract script, eg. adding moving average

use Time::Local;

$cum = 0;
$lasttime = 0;
$lastyear = 0;
while (<>) {
    if ( /^"Country_Exp"/ ) {
        if ( /^"Country_Exp","month","year","AT","BA","BE","BG","CH","CZ","DE","DK","DK","EE","ES","FI","FR","GB","GR","HR","HU","IE","IT","LT","LU","LV","ME","MK","NI","NL","NO","PL","PT","RO","RS","SE","SI","SK","UA","AL","BY","MA","MD","RU","TR","UA","DK"/ ) {
            print "CSV format ok!\n";
        } else {
            die "Bad CSV format!";
        }
        next;
    }
    if ( /^"DE",(\d+),(\d+)/ ) {
        $month = $1 + 0;
        $year  = $2 + 0;
        @parts = split /,/;
        $val   = $parts[23];
        $DELU{$year}{$month} = $val if $val ne "";
#        print "DE->LU $year-$month $val (", ( defined $val ? "defined" : "undef" ), ")\n";
    }
    if ( /^"LU",(\d+),(\d+)/ ) {
        $month = $1 + 0;
        $year  = $2 + 0;
        @parts = split /,/;
        $val   = $parts[9];
        $LUDE{$year}{$month} = $val if $val ne "";
#        print "LU->DE $year-$month $val (", ( defined $val ? "defined" : "undef" ), ")\n";
    }

    /(\d{4})-(\d{2})-(\d{2}): +(-?\d*\.\d*)/ or next;
    $year  = $1;
    $month = $2;
    $day   = $3;
    $val   = $4;
    $unixtime = timelocal( 0, 0, 0, $day, $month-1, $year );

    # Skip data points which are not sequential.  This way it is possible to
    # combine the more up-to-date physical flow data with more accurate, but
    # delayed, final schedules.
    if ( $unixtime <= $lasttime ) {
        print "Skipping duplicate: $_";
        next;
    }

    # Interpolate export to Luxemburg.
    $yearbefore  = $year;
    $monthbefore = ( $month - ( $day < 15 ) );
    if ( $monthbefore == 0 ) {
        $monthbefore = 12;
        $yearbefore--;
    }
    $yearafter  = $year;
    $monthafter = ( $month + ( $day >= 15 ) );
    if ( $monthafter == 13 ) {
        $monthafter = 1;
        $yearafter++;
    }

    # If no Luxemburg data exists, average over (at max) last 4 years.
    $lu{$yearbefore} = $monthbefore;
    $lu{$yearafter}  = $monthafter;
    for $y ( sort keys %lu ) {
        $m = $lu{$y};
        if ( ! defined $LUDE{$y}{$m} ) {
            $n = 0;
            $LUDE{$y}{$m} = 0.;
            for $yy ( reverse sort keys %LUDE ) {
                if ( $yy != $y ) {
                    $LUDE{$y}{$m} += $LUDE{$yy}{$m};
                    $n++;
                    # print "\t", $LUDE{$yy}{$m}, " ($yy)\n";
                }
                last if $n > 3;
            }
            $LUDE{$y}{$m}   /= $n;
            $LUDE_ex{$y}{$m} = 1;
            print "Extrapolated $y-$m LU->DE as ", $LUDE{$y}{$m}, " (n=$n)\n";
        }
        if ( ! defined $DELU{$y}{$m} ) {
            $n = 0;
            $DELU{$y}{$m} = 0.;
            for $yy ( reverse sort keys %DELU ) {
                if ( $yy != $y ) {
                    $DELU{$y}{$m} += $DELU{$yy}{$m};
                    $n++;
                    # print "\t", $DELU{$yy}{$m}, " ($yy)\n";
                }
                last if $n > 3;
            }
            $DELU{$y}{$m}   /= $n;
            $DELU_ex{$y}{$m} = 1;
            print "Extrapolated $y-$m DE->LU as ", $DELU{$y}{$m}, " (n=$n)\n";
        }
    }

    $ubefore   = timelocal( 0, 0, 0, 15, $monthbefore -1, $yearbefore );
    $uafter    = timelocal( 0, 0, 0, 15, $monthafter  -1, $yearafter  );
    $d         = $uafter - $ubefore;
    $lubefore  = $DELU{$yearbefore}{$monthbefore} - $LUDE{$yearbefore}{$monthbefore};
    $luafter   = $DELU{$yearafter }{$monthafter } - $LUDE{$yearafter }{$monthafter };
    $lubefore /= $d;  # GWh/s
    $luafter  /= $d;  # GWh/s


    # Normalized javascript time.  Year is arbitrary because we want to
    # display all years on top of each other Jan-Dec.
    $normtime = timelocal( 0, 0, 0, $day, $month-1, 1984 ) * 1000.;

    # Export to Luxemburg.
    $lasttime ||= $unixtime;  # prevent 0 value
    $delta      = $unixtime - $lasttime;
    $lu1    = $lubefore + ($lasttime-$ubefore)*($luafter-$lubefore)/$d;
    $lu2    = $lubefore + ($unixtime-$ubefore)*($luafter-$lubefore)/$d;
    $lucorr = $delta * ( $lu1 + $lu2 ) / 2.;

    $lasttime = $unixtime;

    $cum = 0 if $lastyear != $year;
    $lastyear = $year;

    $val += $lucorr;

    $cum += $val;
    $times7{$unixtime} = $val;
    $sum7  = 0.;
    $n7    = 0;
    $times30{$unixtime} = $val;
    $sum30 = 0.;
    $n30   = 0;
    foreach $t ( keys %times7 ) {
        if ( $unixtime - $t > 3600 * 24 * 7 ) {
            delete $times7{$t};
            next;
        }
        $sum7 += $times7{$t};
        $n7++;
    }
    foreach $t ( keys %times30 ) {
        if ( $unixtime - $t > 3600 * 24 * 30 ) {
            delete $times30{$t};
            next;
        }
        $sum30 += $times30{$t};
        $n30++;
    }
    $avg7 = $sum7/$n7;
    $avg30 = $sum30/$n30;
    $unixtime -= 1293836400;
    print "$year-$month-$day $val $avg7 $avg30 $cum lucorr: $lucorr\n";
    $flot{$year}{"1"}  {$normtime} = $val;
    $flot{$year}{"7"}  {$normtime} = $avg7;
    $flot{$year}{"30"} {$normtime} = $avg30;
    $flot{$year}{"cum"}{$normtime} = $cum;
}

open( $fdata, ">", "fdata.js" ) or die $!;  # data for flot
print $fdata "var datasets = {\n";

$color = 1;
foreach $year ( sort keys %flot ) {
    $color++;
#    $color++ if $color == 2;
    foreach $tag ( keys %{ $flot{$year} } ) {
        print $fdata "\"$year:$tag\": {\n";
        # disable label to disable legend
        print $fdata "\tlabel: \"Stromexport $year\",\n";
        print $fdata "\tcolor: $color,\n";
        print $fdata "\tdata: [\n";
        foreach $time ( sort keys %{ $flot{$year}{$tag} } ) {
            print $fdata "\t\t[$time, " . $flot{$year}{$tag}{$time} . "],\n";
        }
        print $fdata "\t]},\n";
    }
}

print $fdata "}\n";


foreach $year ( sort keys %DELU ) {
    $ysum = 0;
    foreach $month ( sort { $a <=> $b } keys %{ $DELU{$year} } ) {
        $val = $DELU{$year}{$month}-$LUDE{$year}{$month};
        print "$year-$month: $val (",
        $DELU{$year}{$month}, ( defined $DELU_ex{$year}{$month} ? "e" : "" ),
        " - ", $LUDE{$year}{$month}, ( defined $LUDE_ex{$year}{$month} ? "e" : "" ),
        ")\n";
        $ysum += $val;
    }
    print "$year total: $ysum\n";
}
