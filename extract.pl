#!/usr/bin/perl -w
#
# requires Debian package libxml-simple-perl
#
# semantics:
# "in":  from
# "out": to

#use strict;

my $infile = shift;
my $outfile = shift;

open( my $fh, ">", $outfile ) or die $!;

# use module
use XML::Simple;
use Data::Dumper;

# create object
my $xml = new XML::Simple;

# read XML file
my $data = $xml->XMLin( $infile );

#print Dumper($data);

my $total_hours   = 0;
my $missing_hours = 0;
my $zero_hours    = 0;

my %insum;   # total export sum to Germany grouped by areas
my %outsum;  # total import sum into Germany grouped by areas

my $day = $data->{ScheduleTimeSeries};
foreach my $d ( @{ $day } ) {
    my $in        = $d->{InArea}->{v};
    my $out       = $d->{OutArea}->{v};
    my $intervals = $d->{Period}->{Interval};
    my $time      = $d->{Period}->{TimeInterval}->{v};
    $time =~ /\/(.{10})/;
    $time = $1;
#    print "$out --> $in\n";
    foreach my $hour ( @{ $intervals } ) {
        my $h = $hour->{Pos}->{v};
        my $v = 0.;
        if ( !defined $hour->{Qty}->{v} || $hour->{Qty}->{v} eq "" ) {
            $missing_hours++;
        } else {
            $v = $hour->{Qty}->{v} / 1000.;
        }
        $total_hours++;
        $zero_hours++ if $v == 0.;
#        print "$h: $v\n";
        $insum{$in}   += $v;
        $outsum{$out} += $v;
        $inout{$in}{$out} += $v;
        $outin{$out}{$in} += $v;
        $indetail{$time}{$in}   += $v;
        $outdetail{$time}{$out} += $v;
    }
#    print Dumper( $d );
}

$daycount = 0;
foreach $day ( sort keys %indetail ) {
    $insumde  = 0.;
    $outsumde = 0.;
    foreach $area ( keys %{$indetail{$day}} ) {
        if ( $area =~ /^10YDE/ || $area =~ /^10YCB-GERMANY/ ) {
            $insumde  += $indetail{$day}{$area};
            $outsumde += $outdetail{$day}{$area};
        }
    }
    $saldo = $outsumde - $insumde;
    printf $fh "%s: %5.1f GWh (in: %5.1f GWh, out: %5.1f GWh)\n",
    $day, $saldo, $insumde, $outsumde;
    $daycount++;
}

$format = "%16s saldo: %6.1f GWh (%5.1f GWh/day), imports: %6.1f GWh, exports: %6.1f GWh\n";

$insumde  = 0.;
$outsumde = 0.;
foreach $area ( sort keys %insum ) {
    $saldo  = $outsum{$area} - $insum{$area};
    $perday = $saldo / $daycount;
    printf $format, $area, $saldo, $perday, $insum{$area}, $outsum{$area};

    foreach $out ( sort keys %{$inout{$area}} ) {
        $from = $inout{$area}{$out};
        printf "\t%6.1f GWh from %s\n", $from, $out;
    }
    foreach $in ( sort keys %{$outin{$area}} ) {
        $to = $outin{$area}{$in};
        printf "\t%6.1f GWh to   %s\n", $to, $in;
    }

    if ( $area =~ /^10YDE/ || $area =~ /^10YCB-GERMANY/ ) {
        $insumde  += $insum{$area};
        $outsumde += $outsum{$area};
    }
}

$saldo  = $outsumde - $insumde;
$perday = $saldo / $daycount;
print "\n";
printf $format, "Germany    ", $saldo, $perday, $insumde, $outsumde;
print "\n";
printf "%i = %f%% total hours\n",   $total_hours,   100.;
printf "%i = %f%% zero hours\n",    $zero_hours,    100. * $zero_hours    / $total_hours;
printf "%i = %f%% missing hours\n", $missing_hours, 100. * $missing_hours / $total_hours;
