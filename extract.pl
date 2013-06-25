#!/usr/bin/perl -w
#
# Script to extract data from XML file, build day-sums and convert to simple
# output format.
#
# For rapid development, a DOM-type XML parser was used.  Possibly, speed and
# memory improvements might be achieved by replacing it with a stream-type XML
# parser.
#
# Requires XML::Simple Perl module.  (Debian package: libxml-simple-perl)
#
# semantics:
# "in":  from = source
# "out": to   = target

use diagnostics;
#use strict;

# load modules
use XML::Simple;
use Data::Dumper;

my $infile = shift;
my $outfile = shift;

open( my $fh, ">", $outfile ) or die $!;

# create object
my $xml = new XML::Simple;

# read XML file
my $data = $xml->XMLin( $infile );

#print Dumper($data);

my $total_hours    = 0;
my $missing_hours  = 0;
my $missing_days   = 0;
my $missing_phours = 0;  # hours for which only one direction is missing
my $total_days     = 0;
my $missing_pdays  = 0;  # missing partial days
my $zero_hours     = 0;

my %insum;        # total sum of export for given area
my %outsum;       # total sum of import for given area
my %inout;        # total sum of transfer from 1st given area to 2nd given area
my %indetail;     # sum of export for given date and given area
my %outdetail;    # sum of import for given date and given area
my %inoutdetail;  # sum of transfer for given date from 1st given area to 2nd given area
my %inoutvalid;   # number of valid data points for (date,from,to)
my %inouttotal;   # number of valid data points for (date,from,to)


#
# obtain day-sum statistics
#
sub normalize_name( $ );
my $day = $data->{ScheduleTimeSeries};
foreach my $d ( @{ $day } ) {
    my $in        = normalize_name( $d->{InArea}->{v} );
    my $out       = normalize_name( $d->{OutArea}->{v} );
    my $intervals = $d->{Period}->{Interval};
    my $date      = $d->{Period}->{TimeInterval}->{v};
    $date =~ /\/(.{10})/;  # dates obtained this way are in UTC+1 = winter time
    $date = $1;
#    print "$out --> $in\n";

#    die "Bad data: expecting only transfers from/to Germany." if $in ne 'DE' && $out ne 'DE';
    next if $in ne 'DE' && $out ne 'DE';


    foreach my $hour ( @{ $intervals } ) {
        my $h = $hour->{Pos}->{v};
        my $v = 0.;
        if ( !defined $hour->{Qty}->{v} || $hour->{Qty}->{v} eq "" ) {
            $missing_hours++;
        } else {
            $v = $hour->{Qty}->{v} / 1000.;
	    $inoutvalid{$date}{$in}{$out}++;
	    $zero_hours++ if $v == 0.;
        }
	$inouttotal{$date}{$in}{$out}++;
        $total_hours++;
#        print "$h: $v\n";
        $insum{$in}                    += $v;
        $outsum{$out}                  += $v;
        $inout{$in}{$out}              += $v;
        $indetail{$date}{$in}          += $v;
        $outdetail{$date}{$out}        += $v;
	$inoutdetail{$date}{$in}{$out} += $v;
    }
    $total_days++;
#    print Dumper( $d );
}


#
# write statistics to output file
#
my $daycount = 0;
printf $fh '#   date  %8s', 'total';
foreach $area ( sort keys %insum ) {
    next if $area eq 'DE';
    printf $fh "%8s ", $area;
}
print $fh "\n";
foreach $day ( sort keys %indetail ) {
    my $insumde  = 0.;
    my $outsumde = 0.;
    my $total = $outdetail{$day}{'DE'} - $indetail{$day}{'DE'};
    printf $fh "%s %8.3f ", $day, $total;
    foreach $area ( sort keys %insum ) {
	next if $area eq 'DE';
	# require at least one valid hour in any direction
	if ( defined $inoutvalid{$day}{$area}{'DE'} && $inoutvalid{$day}{$area}{'DE'} > 0
	     && defined $inoutvalid{$day}{'DE'}{$area} && $inoutvalid{$day}{'DE'}{$area} > 0 ) {
            my $saldo = $inoutdetail{$day}{$area}{'DE'} - $inoutdetail{$day}{'DE'}{$area};
            printf $fh "%8.3f ", $saldo;
	} else {
            printf $fh "%8s ", "N/A";
	}
    }
    printf $fh "\n";
    $daycount++;
}


#
# write summary statistics to stdout
#
my $insumde  = 0.;
my $outsumde = 0.;
my $format = "%s saldo: %7.1f GWh (%5.1f GWh/day), imports: %7.1f GWh, exports: %7.1f GWh\n";
foreach $area ( sort keys %insum ) {
    $saldo  = $outsum{$area} - $insum{$area};
    $perday = $saldo / $daycount;
    printf $format, $area, $saldo, $perday, $insum{$area}, $outsum{$area};

    foreach $out ( sort keys %{$inout{$area}} ) {
        $from = $inout{$area}{$out};
        printf "\t%7.1f GWh from %s\n", $from, $out;
    }
    foreach $in ( sort keys %{$inout{$area}} ) {
        $to = $inout{$in}{$area};
        printf "\t%7.1f GWh to   %s\n", $to, $in;
    }

    if ( $area eq 'DE' ) {
        $insumde  += $insum{$area};
        $outsumde += $outsum{$area};
    }
}

$saldo  = $outsumde - $insumde;
$perday = $saldo / $daycount;
print "\n";
printf $format, "Germany    ", $saldo, $perday, $insumde, $outsumde;
print "\n";
print "Hours:\n";
printf "%i = %f%% total\n",                    $total_hours,    100.;
printf "%i = %f%% zero\n",                     $zero_hours,     100. * $zero_hours    / $total_hours;
printf "%i = %f%% missing\n",                  $missing_hours,  100. * $missing_hours / $total_hours;
printf "%i = %f%% missing in one direction\n", $missing_phours, 100. * $missing_phours / $total_hours;
print "\n";
print "Days:\n";
printf "%i = %f%% total\n",              $total_days,    100.;
printf "%i = %f%% missing\n",            $missing_days,  100. * $missing_days  / $total_days;
printf "%i = %f%% partially missing\n",  $missing_pdays, 100. * $missing_pdays / $total_days;


sub normalize_name( $ ) {
    my $name = shift;
    if ( $name =~ /^10YAT/ || $name =~ /^10YCB-AUSTRIA/ ) {
	$name = 'AT';
    } elsif ( $name =~ /^10YCZ/ ) {
	$name = 'CZ';
    } elsif ( $name =~ /^10YCH/ ) {
	$name = 'CH';
    } elsif ( $name =~ /^10YDE/ || $name =~ /^10YCB-GERMANY/ ) {
	$name = 'DE';
    } elsif ( $name =~ /^10YDK/ ) {
	$name = 'DK';
    } elsif ( $name =~ /^10YFR/ ) {
	$name = 'FR';
    } elsif ( $name =~ /^10YNL/ ) {
	$name = 'NL';
    } elsif ( $name =~ /^10YPL/ ) {
	$name = 'PL';
    } elsif ( $name =~ /^10YSE/ || $name eq '10Y1001A1001A47J' ) {
	$name = 'SE';
    } else {
	$name = '??';
#	die "Unknown area: '$name'";
    }
    return $name;
}
