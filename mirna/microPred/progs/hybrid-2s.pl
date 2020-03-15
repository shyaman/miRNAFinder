#! /usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

use constant R => .0019872;

sub version ($) {
    print "$_[0] (UNAFold) 3.6\n";
    print "By Nicholas R. Markham and Michael Zuker\n";
    print "Copyright (C) 2006\n";
    print "Rensselaer Polytechnic Institute\n";
    print "Troy, NY 12810-3590 USA\n";
    exit;
}

sub usage () {
    print <<EOF;
Usage: hybrid-2s.pl [options] file1 file2

Options:
-n, --NA=(RNA | DNA) (defaults to RNA)
-t, --tmin=<minimum temperature> (defaults to 0)
-i, --tinc=<temperature increment> (defaults to 1)
-T, --tmax=<maximum temperature> (defaults to 100)
-N, --sodium=<[Na+] in M> (defaults to 1)
-M, --magnesium=<[Mg++] in M> (defaults to 0)
-p, --polymer
-h, --prohibit=<i,j,k>
-f, --force=<i,j,k>
-E, --energyOnly
-I, --noisolate
-F, --mfold=<P,W,MAX> (defaults to 5,3,100)
-c, --constraints=<name of constraints file>
-b, --basepairs=<name of basepairs file>
    --temperature=<hybridization temperature>

Obscure options:
    --allpairs
    --maxloop=<maximum bulge/interior loop size> (defaults to 30)
    --nodangle
    --prefilter=<filter value>

EOF
print 'Report bugs to markhn@rpi.edu', "\n";
    exit;
}

my ($tMin, $tInc, $tMax, $temp) = (0, 1, 100, 37);
my ($energyOnly, @prohibit, @force);
my %options;

GetOptions \%options, 'version|V' => sub { version('hybrid-2s.pl') }, 'help|h' => sub { usage() }, 'NA|n=s', 'tmin|t=f' => \$tMin, 'tinc|i=f' => \$tInc, 'tmax|T=f' => \$tMax, 'allpairs', 'sodium|N=f', 'magnesium|M=f', 'polymer|p', 'prohibit|r=s' => \@prohibit, 'force|f=s' => \@force, 'energyOnly|E' => \$energyOnly, 'noisolate|I', 'mfold|F:s', 'constraints|c:s', 'basepairs|b=s', 'maxloop=i', 'nodangle', 'prefilter=s', 'temperature=f' => \$temp or die $!;

my @args = ('--tmin' => $temp, '--tmax' => $temp);
foreach (keys %options) {
    if ($_ eq 'allpairs' or $_ eq 'nodangle' or $_ eq 'polymer' or $_ eq 'noisolate') {
	push @args, "--$_";
    } else {
	push @args, "--$_";
	push @args, $options{$_} if defined $options{$_};
    }
}

my ($file1, $file2) = @ARGV;
unless (defined $file1 and defined $file2) {
    print STDERR "Error: data not specified\nRun 'hybrid-2s.pl -h' for help\n";
    exit 1;
}
my ($prefix1, $prefix2);
($prefix1 = $file1) =~ s/\.seq$//;
($prefix2 = $file2) =~ s/\.seq$//;
my $prefix = "$prefix1-$prefix2";

system('hybrid-min', @args, $file1, $file2) == 0 or die $!;

my (@struct, @dG, @dH, @dS);

my $len1;
open IN, "<$prefix.ct" or die $!;
while (<IN>) {
    chomp;
    my ($len, $dG) = /^(.+)\tdG = (.+?)\t/;
    push @dG, $dG;
    my @ss;
    for (my $i = 0; $i < $len; ++$i) {
	my $line = <IN>;
	$ss[$i] = (split "\t", $line)[4] ? 0 : 1;
	$len1 = $i if (split "\t", $line)[2] == 0;
    }
    push @struct, \@ss;
}
close IN or die $!;

my $suffix = (defined $options{NA} and $options{NA} eq 'DNA') ? 'DHD' : 'DH';
open IN, "ct-energy -s$suffix $prefix.ct|" or die $!;
while (<IN>) {
    chomp;
    s/inf/999999/;
    push @dH, $_;
}
close IN or die $!;

for (my $i = 0; $i < @dG; ++$i) {
    if ($dG[$i] > 500) {
	push @dS, -999999;
    } else {
	push @dS, ($dH[$i] - $dG[$i]) / (273.15 + $temp);
    }
}

open IN, "<$prefix.$temp.ext" or die $!;
while (<IN>) {
    /^1\t(\d+)/ and $len1 = $1;
    /^2\t(\d+)/ and $struct[0][$1 + $len1 - 1] = 0;
}
close IN or die $!;

open OUT, ">$prefix.dG" or die $!;
print OUT "#T\t-RT ln Z\tZ\n";
for (my $t = $tMin; $t <= $tMax; $t += $tInc) {
    my $z = 0;
    my @p1 = (0) x @{$struct[0]};
    my @p2 = (0) x (@{$struct[0]} - 1);
    for (my $i = 0; $i < @dG; ++$i) {
	$z += exp(-($dH[$i] - (273.15 + $t) * $dS[$i]) / R / (273.15 + $t));
    }
    for (my $i = 0; $i < @dG; ++$i) {
	for (my $j = 0; $j < @{$struct[$i]}; ++$j) {
	    $p1[$j] += exp(-($dH[$i] - (273.15 + $t) * $dS[$i]) / R / (273.15 + $t)) / $z if $struct[$i][$j];
	    $p2[$j] += exp(-($dH[$i] - (273.15 + $t) * $dS[$i]) / R / (273.15 + $t)) / $z if $j < @{$struct[$i]} - 1 and $struct[$i][$j] and $struct[$i][$j + 1];
	}
    }
    if ($z == 0) {
	printf OUT "%g\t%s\t%g\n", $t, 'inf', 0;
    } else {
	printf OUT "%g\t%g\t%g\n", $t, - R * (273.15 + $t) * log($z), $z;
    }

    unless ($energyOnly) {
	open OUT2, ">$prefix.$t.ext" or die $!;
	print OUT2 "sequence\ti/j\tP(i is SS)\tP(i is SS and i+1 is SS)\n";
	for (my $i = 0; $i < $len1 - 1; ++$i) {
	    printf OUT2 "1\t%d\t%g\t%g\n", $i + 1, $p1[$i], $p2[$i];
	}
	printf OUT2 "1\t%d\t%g\n", $len1, $p1[$len1 - 1];
	for (my $i = $len1; $i < @{$struct[0]} - 1; ++$i) {
	    printf OUT2 "2\t%d\t%g\t%g\n", $i + 1 - $len1, $p1[$i], $p2[$i];
	}
	printf OUT2 "2\t%d\t%g\n", @{$struct[0]} - $len1, $p1[@{$struct[0]} - 1];
	close OUT2 or die $!;
    }
}
close OUT or die $!;
