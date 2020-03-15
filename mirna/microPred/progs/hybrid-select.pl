#! /usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

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
Usage: hybrid-select.pl [options] file1 [file2]

Options:
-n, --NA=(RNA | DNA) (defaults to RNA)
-t, --t=<temperature> (defaults to 37)
-s, --suffix=<free energy suffix>
-N, --sodium=<[Na+] in M> (defaults to 1)
-M, --magnesium=<[Mg++] in M> (defaults to 0)
-p, --polymer
-h, --prohibit=<i,j,k>
-f, --force=<i,j,k>
-I, --noisolate
-F, --mfold=<P,W,MAX> (defaults to 5,3,100)
-k, --tracebacks=<number of tracebacks>
-m, --maxbp=<maximum basepair distance>
-c, --constraints=<name of constraint file> (defaults to prefix.aux)
-C, --cutoff=<energy/probability cutoff> (defaults to 5%/0.001)
    --initial=<first program> (defaults to PF)
    --final=<second program> (defaults to EM)

Obscure options:
    --allpairs
    --maxloop=<maximum bulge/interior loop size> (defaults to 30)
    --nodangle
    --simple
    --prefilter=<filter value>
    --nopostfilter
EOF
    print 'Report bugs to markhn@rpi.edu', "\n";
    exit;
}

my ($temp, $cutoff, $prog1, $prog2) = (37, undef, 'PF', 'EM');
my ($mfold, $tracebacks, @prohibit, @force);
my %options;

GetOptions \%options, 'version|V' => sub { version('hybrid-select.pl') }, 'help|h' => sub { usage() }, 'NA|n=s', 't=f' => \$temp, 'suffix|s=s', 'allpairs', 'maxloop=i', 'sodium|N=f', 'magnesium|M=f', 'polymer|p', 'prohibit|r=s' => \@prohibit, 'force|f=s' => \@force, 'nodangle', 'simple', 'prefilter=s', 'nopostfilter', 'energyOnly|E', 'noisolate|I', 'mfold|F:s' => \$mfold, 'tracebacks|k=i' => \$tracebacks, 'maxbp|m=i', 'constraints|c:s', 'cutoff|C=f' => \$cutoff, 'initial=s' => \$prog1, 'final=s' => \$prog2 or die $!;

my @args = ('--tmin' => $temp, '--tmax' => $temp);

foreach (keys %options) {
    if ($_ eq 'allpairs' or $_ eq 'nodangle' or $_ eq 'polymer' or $_ eq 'noisolate'or $_ eq 'simple' or $_ eq 'nopostfilter') {
	push @args, "--$_";
    } else {
	push @args, "--$_";
	push @args, $options{$_} if $options{$_};
    }
}

push @args, '--prohibit' => $_ foreach @prohibit;
push @args, '--force' => $_ foreach @force;

unless ($ARGV[0]) {
    print STDERR "Error: file not specified\nRun 'hybrid-select.pl -h' for help\n";
    exit 1;
}
my ($file1, $file2) = @ARGV;
defined $file2 or $file2 = '';
my ($prefix1, $prefix2);
($prefix1 = $file1) =~ s/\.seq$//;
($prefix2 = $file2) =~ s/\.seq$// if $file2;

my $prefix = $file2 ? "$prefix1-$prefix2" : $prefix1;

my ($seq1, $seq2);
open IN, '<', $file1 or open IN, '<', "$file1.seq" or die $!;
$seq1 = join '', <IN>;
close IN or die $!;
$seq1 =~ tr/A-Za-z0-9//cd;
if ($file2) {
    open IN, '<', $file2 or open IN, '<', "$file2.seq" or die $!;
    $seq2 = join '', <IN>;
    close IN or die $!;
    $seq2 =~ tr/A-Za-z0-9//cd;
}

for ($prog1, $prog2) {
    if ($_ eq 'PF') {
	$_ = $file2 ? 'hybrid' : 'hybrid-ss';
    } elsif ($_ eq 'EM') {
	$_ = $file2 ? 'hybrid-min' : 'hybrid-ss-min';
    }
    if ($_ eq 'hybrid-ss' and $options{nodangle} and $options{simple}) {
	print "Replacing hybrid-ss --nodangle --simple with hybrid-ss-simple\n";
	$_ = 'hybrid-ss-simple';
    } elsif ($_ eq 'hybrid-ss' and length $seq1 <= 11) {
	print "Replacing hybrid-ss with hybrid-ss-noml\n";
	$_ = 'hybrid-ss-noml';
    }
}

print "Warning: ignoring --mfold option\n" if defined $mfold and $prog2 !~ /min/;
print "Warning: ignoring --tracebacks olption\n" if defined $tracebacks and $prog2 =~ /min/;

unless (defined $cutoff) {
    if ($prog1 =~ /min/) {
	$cutoff = 5;
    } else {
	$cutoff = 0.001;
    }
}

system($prog1, ($prog1 =~ /min/ ? '--mfold' : ()), @args, $file1, $file2) == 0 or die $!;

if ($prog1 =~ /min/) {
    open IN, '<', "$prefix.dG" or die $!;
    scalar <IN>;
    $_ = scalar <IN>;
    my (undef, $dG, undef) = split;
    $cutoff = (100 - $cutoff) * $dG / 100;
    close IN or die $!;

    open IN, '<', "$prefix.plot" or die $!;
    open OUT, '>', "$prefix.bp" or die $!;
    scalar <IN>;
    while (<IN>) {
	chomp;
	my (undef, $k, $i, $j, $e) = split or next;
	$i > 0 and $j > 0 and $k > 0 and $e / 10.0 < $cutoff or next;
	$j -= length($seq1) if $file2;
	print OUT "$i\t$j\t$k\n";
    }
    close OUT or die $!;
    close IN or die $!;
} else {
    open IN, '<', "$prefix.$temp.plot" or die $!;
    open OUT, '>', "$prefix.bp" or die $!;
    scalar <IN>;
    while (<IN>) {
	chomp;
	my ($i, $j, $p) = split or next;
	$i > 0 and $j > 0 and $p > $cutoff or next;
	print OUT "$i\t$j\t1\n";
    }
    close OUT or die $!;
    close IN or die $!;
}

if (defined $mfold) {
    push @args, '--mfold';
    $args[$#args] .= '=' . $mfold if $mfold;
}
push @args, '--tracebacks' => $tracebacks if $tracebacks;

system($prog2, @args, '--basepairs' => "$prefix.bp", $file1, $file2) == 0 or die $!;
