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
open Bf, ">$prefix.Bf" or die $!; print Bf "#T\t[Bf\n";
open Au, ">$prefix.Au" or die $!; print Au "#T\t[Au]\n";
open Bu, ">$prefix.Bu" or die $!; print Bu "#T\t[Bu]\n";
open A,  ">$prefix.A" or die $!; print A "#T\t[A]\n";
open B,  ">$prefix.B" or die $!; print B "#T\t[B]\n";
open AA, ">$prefix.AA" or die $!; print AA "#T\t[AA]\n";
open BB, ">$prefix.BB" or die $!; print BB "#T\t[BB]\n";
open AB, ">$prefix.AB" or die $!; print AB "#T\t[AB]\n";

my @single;
my $minSingle = 999999;
my ($A0old, $B0old);
while (<IN>) {
    next unless /^\d/ or /^-\d/;
    my ($T, $Af, $Bf, $A, $B, $AA, $BB, $AB) = split /\t/;
    my $A0 = $A + 2 * $AA + $AB;
    my $B0 = $B + 2 * $BB + $AB;
    my $Au = $A - $Af;
    my $Bu = $B - $Bf;
    if (defined $A0old and defined $B0old) {
	abs($A0 - $A0old) / $A0 < $TOLERANCE or printf STDERR "Warning: at $T degrees the relative error of [A]+2[AA]+[AB] is %g\n", abs($A0 - $A0old) / $A0;
	abs($B0 - $B0old) / $B0 < $TOLERANCE or printf STDERR "Warning: at $T degrees the relative error of [B]+2[BB]+[AB] is %g\n", abs($B0 - $B0old) / $B0;
    } else {
	$A0old = $A0;
	$B0old = $B0;
    }

    my $total = $A + $B + $AA + $BB + $AB;
    $Af /= $total;
    $Bf /= $total;
    $Au /= $total;
    $Bu /= $total;
    $A /= $total;
    $B /= $total;
    $AA /= $total;
    $BB /= $total;
    $AB /= $total;

    print Af "$T\t$Af\n";
    print Bf "$T\t$Bf\n";
    print Au "$T\t$Au\n";
    print Bu "$T\t$Bu\n";
    print A "$T\t$A\n";
    print B "$T\t$B\n";
    print AA "$T\t$AA\n";
    print BB "$T\t$BB\n";
    print AB "$T\t$AB\n";

    my $single = ($Au + $Bu) * $total;
    $minSingle = $single if $single < $minSingle;
    push @single, [$T, $single];
}

close IN or die $!;
close Af or die $!;
close Bf or die $!;
close Au or die $!;
close Bu or die $!;
close A  or die $!;
close B  or die $!;
close AA or die $!;
close BB or die $!;
close AB or die $!;

my $value = ($minSingle + $A0old + $B0old) / 2.0;
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
