#! /usr/bin/perl -w

use strict;
use warnings;

my $TOLERANCE = 1e-5;

unless (@ARGV) {
    print "Usage: $0 prefix\n";
    exit;
}

my $prefix = $ARGV[0];

open IN, "<$prefix.conc" or die $!;
open Af, ">$prefix.Af" or die $!; print Af "#T\t[Af]\n";
open Au, ">$prefix.Au" or die $!; print Au "#T\t[Au]\n";
open A,  ">$prefix.A" or die $!; print A "#T\t[A]\n";
open AA, ">$prefix.AA" or die $!; print AA "#T\t[AA]\n";

my @single;
my $minSingle = 999999;
my ($A0old, $B0old);
while (<IN>) {
    next unless /^\d/ or /^-\d/;
    my ($T, $Af, $A, $AA) = split /\t/;
    my $Au = $A - $Af;
    my $A0 = $A + 2 * $AA;
    if (defined $A0old) {
	abs($A0 - $A0old) / $A0 < $TOLERANCE or printf STDERR "Warning: at $T degrees the relative error of [A]+2[AA] is %g\n", abs($A0 - $A0old) / $A0;
    } else {
	$A0old = $A0;
    }

    my $total = $A + $AA;
    $Af /= $total;
    $Au /= $total;
    $A /= $total;
    $AA /= $total;

    print Af "$T\t$Af\n";
    print Au "$T\t$Au\n";
    print A "$T\t$A\n";
    print AA "$T\t$AA\n";

    my $single = $Au * $total;
    $minSingle = $single if $single < $minSingle;
    push @single, [$T, $single];
}

close IN or die $!;
close Af or die $!;
close Au or die $!;
close A  or die $!;
close AA or die $!;

my $value = ($minSingle + $A0old) / 2.0;
open TMCONC, ">$prefix.TmConc" or die $!;
for (my $i = 0; $i < $#single; ++$i) {
    if ($single[$i][1] <= $value && $single[$i + 1][1] >= $value) {
	if ($single[$i][1] == $single[$i + 1][1]) {
	    printf TMCONC "%g\t%g\n", ($single[$i][0] + $single[$i + 1][0]) / 2, 1.0;
	} else {
	    printf TMCONC "%g\t%g\n", ($single[$i][0] - $single[$i + 1][0]) * ($value - $single[$i + 1][1]) / ($single[$i][1] - $single[$i + 1][1]) + $single[$i + 1][0], 1.0;
	}
    }
}
close TMCONC or die $!;
