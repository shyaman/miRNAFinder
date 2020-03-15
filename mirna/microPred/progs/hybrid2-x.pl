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

my ($scriptName) = $0 =~ /([^\/]+)$/;

sub usage () {
    print <<EOF;
Usage: hybrid2.pl [options] --A0=[A0] --B0=[B0] file1 file2

Options:
-V, --version
-h, --help
-n, --NA=(RNA | DNA) (defaults to RNA)
-t, --tmin=<minimum temperature> (defaults to 0)
-i, --tinc=<temperature increment> (defaults to 1)
-T, --tmax=<maximum temperature> (defaults to 100)
-N, --sodium=<[Na+] in M> (defaults to 1)
-M, --magnesium=<[Mg++] in M> (defaults to 0)
-A, --A0=<total A>
-B, --B0=<total B>
-p, --polymer
-E, --energyOnly
-I, --noisolate
-z, --zip
EOF
    print "-F, --mfold[=<P,W,MAX>] (defaults to 5,3,100)\n" if $scriptName =~ /2s/;
    print "-m, --maxbp=<maximum basepair distance>\n";
    print "-x, --exclude=(A|B|AA|BB)\n";
#    print "-H, --enthalpy=<enthalpy for unfolded strands> (defaults to +infinity)\n";
#    print "-S, --entropy=<entropy for unfolded strands> (defaults to -infinity)\n";
    print "    --fraction=<fraction of ensemble enthalpy> (defaults to 0.1)\n";
    print "    --nofraction\n";
    print "    --Tmelt=<melting temp. for single strands> (defaults to 50)\n";
    print "    --old-dHss\n";
#    print "    --power=<exponent for open P.F.> (defaults to 1)\n";
#    print "-Y, --infinity\n";
    print "-P, --parallel\n";
    print "-r, --reuse\n";
    print "    --title=<plot title>\n";
    print "    --temperature=<two-state temperature> (defaults to 50)\n" if $scriptName =~ /2s/;
    print <<EOF;

Obscure options:
    --allpairs
    --maxloop=<maximum bulge/interior loop size> (defaults to 30)
    --nodangle
    --simple
    --single
    --prefilter=<filter value>
    --nopostfilter

EOF
    print 'Report bugs to markhn@rpi.edu', "\n";
    exit;
}

sub systemError ($) {
    die ($? == -1 ? "Error: $! from $_[0]\n" : 'Exit status ' . ($? >> 8) . " from $_[0]\n")
}

my ($tmin, $tinc, $tmax, $temp2s) = (0, 1, 100, 50);
my ($dH, $dS, $fraction, $tMelt, $power, $olddHss) = (undef, undef, 0.1, 50, 1, 0);
my $HYBRID = 'hybrid';
my $HYBRID_SS = 'hybrid-ss';
$HYBRID = 'hybrid-intra' if $scriptName =~ /intra/;
if ($scriptName =~ /min/) {
    if ($scriptName =~ /intra/) {
	$HYBRID = 'hybrid-intra-min';
    } else {
	$HYBRID = 'hybrid-min';
    }
    $HYBRID_SS = 'hybrid-ss-min';
} elsif ($scriptName =~ /2s/) {
    $HYBRID = 'hybrid-2s.pl';
    $HYBRID_SS = 'hybrid-ss-2s.pl';
}
my ($A0, $B0, @exclude, %options);
@exclude = ('A', 'B', 'AA', 'BB') if $scriptName =~ /x/;
$options{energyOnly} = 1 if $HYBRID eq 'hybrid-intra';
$options{NA} = 'RNA';

GetOptions \%options, 'version|V' => sub { version('hybrid2.pl') }, 'help|h' => sub { usage() }, 'NA|n=s', 'tmin|t=f' => \$tmin, 'tinc|i=f' => \$tinc, 'tmax|T=f' => \$tmax, 'enthalpy|H=f' => \$dH, 'entropy|S=f' => \$dS, 'fraction=f' => \$fraction, 'nofraction' => sub { $fraction = undef }, 'Tmelt=f' => \$tMelt, 'old-dHss' => \$olddHss, 'infinity|Y', 'power=f' => \$power, 'allpairs', 'maxloop=i', 'sodium|N=f', 'magnesium|M=f', 'A0|A=f' => \$A0, 'B0|B=f' => \$B0, 'exclude|x=s' => \@exclude, 'parallel|P', 'reuse|r', 'title=s', 'polymer|p', 'nodangle', 'simple', 'prefilter=s', 'nopostfilter', 'energyOnly|E', 'noisolate|I', 'zip|z', 'mfold|F:s', 'single', 'maxbp|m=i', 'temperature=f' => \$temp2s or die $!;
my ($tmin_original, $tmax_original) = ($tmin, $tmax);
my $points = int(5 / sqrt($tinc));
$points >= 2 or $points = 2;
$tmax += $points * $tinc;
$tmin -= $points * $tinc;
my @args = ('--tmin' => $tmin, '--tinc' => $tinc, '--tmax' => $tmax);
push @args, '--temperature' => $temp2s if $scriptName =~ /2s/;
foreach (keys %options) {
    next if $_ eq 'parallel';
    next if $_ eq 'reuse';
    next if $_ eq 'single';
    next if $_ eq 'infinity';
    next if $_ eq 'title';
    if ($_ eq 'allpairs' or $_ eq 'nodangle' or $_ eq 'simple' or $_ eq 'nopostfilter' or $_ eq 'polymer' or $_ eq 'energyOnly' or $_ eq 'noisolate' or $_ eq 'zip') {
	push @args, "--$_";
    } else {
	push @args, "--$_";
	push @args, $options{$_} if defined $options{$_};
    }
}
defined $options{sodium} or $options{sodium} = 1.0;
my ($exclA, $exclB, $exclAA, $exclBB);
foreach my $x (@exclude) {
    if ($x eq 'A') {
	++$exclA;
    } elsif ($x eq 'B') {
	++$exclB;
    } elsif ($x eq 'AA') {
	++$exclAA;
    } elsif ($x eq 'BB') {
	++$exclBB;
    }
}

unless (@ARGV >= 2) {
    print STDERR "Error: files not specified\nRun 'hybrid2.pl -h' for help\n";
    exit 1;
}
my ($file1, $file2) = @ARGV;
my ($prefix1, $prefix2, $seq1, $seq2);
($prefix1 = $file1) =~ s/\.seq$//;
$prefix1 =~ s/^.+[\/\\]//;

my $same;
open IN, '<', $file1 or open IN, '<', "$file1.seq" or die $!;
$seq1 = join '', <IN>;
close IN or die $!;
$seq1 =~ tr/A-Za-z0-9//cd;

if (defined $file2 and $file2 ne $file1) {
    ($prefix2 = $file2) =~ s/\.seq$//;
    $prefix2 =~ s/^.+[\/\\]//;
    open IN, '<'. $file2 or open IN, '<', "$file2.seq" or die $!;
    $seq2 = join '', <IN>;
    close IN or die $!;
    $seq2 =~ tr/A-Za-z0-9//cd;
    $same = sameSequence($seq1, $seq2);
} else {
    $same = 1;
}
my $prefix = $same ? "$prefix1-$prefix1" : "$prefix1-$prefix2";

my @concArgs;
if (defined $dH and defined $dS) {
    if ($same) {
	@concArgs = (-H => $dH, -S => $dS);
    } else {
	my $dHa = $dH * length($seq1) / (length($seq1) + length($seq2));
	my $dHb = $dH * length($seq2) / (length($seq1) + length($seq2));
	my $dSa = $dS * length($seq1) / (length($seq1) + length($seq2));
	my $dSb = $dS * length($seq2) / (length($seq1) + length($seq2));
	@concArgs = (-H => "$dHa,$dHb", -S => "$dSa,$dSb");
    }
    push @concArgs, -b => $power;
}
push @concArgs, -x => 'A' if $exclA;
push @concArgs, -x => 'B' if $exclB;
push @concArgs, -x => 'AA' if $exclAA;
push @concArgs, -x => 'BB' if $exclBB;
my @extArgs = ('--NA' => $options{NA});
push @extArgs, '--single' if $options{single};
push @concArgs, '-Y' if $options{infinity};

$HYBRID_SS = 'hybrid-ss-simple' if $options{nodangle} and $options{simple} and $HYBRID_SS = 'hybrid-ss';

if ($same and not defined $A0) {
    print "Error: strand concentration must be specified with -A/--A0\n";
    exit 0;
} elsif (not $same and (not defined $A0 or not defined $B0)) {
    print "Error: strand concentrations must be specified with -A/--A0 and -B/--B0\n";
    exit 0;
}

if ($same) {
    if ($options{reuse}) {
	$exclA or -e "$prefix1.dG" or die "$prefix1.dG not found";
	$exclAA or -e "$prefix1-$prefix1.dG" or die "$prefix1-$prefix1.dG not found";
    } else {
	if ($options{parallel}) {
	    $exclAA or my $pid1 = fork or exec $HYBRID, @args, $file1, $file1 or die $!;
	    $exclA or my $pid2 = fork or exec $HYBRID_SS, @args, $file1 or die $!;
	    waitpid $pid1, 0 unless $exclAA;
	    waitpid $pid2, 0 unless $exclA;
	} else {
	    $exclAA or system($HYBRID, @args, $file1, $file1) == 0 or systemError($HYBRID);
	    $exclA or system($HYBRID_SS, @args, $file1) == 0 or systemError($HYBRID_SS);
	}
    }

    if ($options{infinity}) {
	unless ($exclA) {
	    my $ZaInf;
	    open IN, '<', "$prefix1.dG" or die $!;
	    scalar <IN>;
	    while (<IN>) {
		my ($t, $g, $z) = split;
		$ZaInf = $z unless defined $ZaInf and $ZaInf < $z;
		
	    }
	    close IN or die $!;
	    open OUT, '>', "$prefix1.inf" or die $!;
	    print OUT "$ZaInf\n";
	    close OUT or die $!;
	}
	unless ($exclAA) {
	    my $ZaaInf;
	    open IN, '<', "$prefix1-$prefix1.dG" or die $!;
	    scalar <IN>;
	    while (<IN>) {
		my ($t, $g, $z) = split;
		$ZaaInf = $z unless defined $ZaaInf and $ZaaInf < $z;
		
	    }
	    close IN or die $!;
	    open OUT, '>', "$prefix1-$prefix1.inf" or die $!;
	    print OUT "$ZaaInf\n";
	    close OUT or die $!;
	}
    }

    if (defined $fraction) {
	if ($olddHss) {
	    system('concentration-same', -A => $A0, @concArgs, $prefix1) == 0 or systemError('concentration-same');
	    system('ensemble-dg-same', @concArgs, $prefix1) == 0 or systemError('ensemble-dg-same');
	    system('dG2dH', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dH');
	    open IN, '<', "$prefix.ens.dH" or die $!;
	    chomp($dH = <IN>);
	    close IN or die $!;
	    $dH *= -$fraction;
	} else {
	    chomp($dH = `sbs --NA=$options{NA} $file1`);
	    $dH *= $fraction / 2.0;
	}
	$dS = $dH / ($tMelt + 273.15) * 1000.0;
	push @concArgs, -H => $dH, -S => $dS;
    }

    system('concentration-same', -A => $A0, @concArgs, $prefix1) == 0 or systemError('concentration-same');
    system('concentrations-same.pl', "$prefix1-$prefix1") == 0 or systemError('concentrations-same.pl');
    system('ensemble-dg-same', @concArgs, $prefix1) == 0 or systemError('ensemble-dg-same');
    system('dG2Cp', '--points' => $points, "$prefix1-$prefix1.A.dG") == 0 or systemError('dG2Cp');
    system('dG2Cp', '--points' => $points, "$prefix1-$prefix1.AA.dG") == 0 or systemError('dG2Cp');
    system('dG2Cp', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2Cp');
    system('dG2dH', '--points' => $points, "$prefix.A.dG") == 0 or systemError('dG2dH');
    system('dG2dH', '--points' => $points, "$prefix.AA.dG") == 0 or systemError('dG2dH');
    system('dG2dH', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dH');
    system('dG2dS', '--points' => $points, "$prefix.A.dG") == 0 or systemError('dG2dS');
    system('dG2dS', '--points' => $points, "$prefix.AA.dG") == 0 or systemError('dG2dS');
    system('dG2dS', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dS');
    $options{energyOnly} or system('ensemble-ext-same', '--points' => $points, @concArgs, @extArgs, $file1) == 0 or systemError('ensemble-ext-same');
    plot($seq1, $seq2);
    exit;
}

if ($options{reuse}) {
    $exclA or -e "$prefix1.dG" or die "$prefix1.dG not found";
    $exclB or -e "$prefix2.dG" or die "$prefix2.dG not found";
    $exclAA or -e "$prefix1-$prefix1.dG" or die "$prefix1-$prefix1.dG not found";
    -e "$prefix1-$prefix2.dG" or die "$prefix1-$prefix2.dG not found";
    $exclBB or -e "$prefix2-$prefix2.dG" or die "$prefix2-$prefix2.dG not found";
} else {
    if ($options{parallel}) {
	my $pid1 = fork or exec $HYBRID, @args, $file1, $file2 or die $!;
	$exclAA or my $pid2 = fork or exec $HYBRID, @args, $file1, $file1 or die $!;
	$exclBB or my $pid3 = fork or exec $HYBRID, @args, $file2, $file2 or die $!;
	$exclA or my $pid4 = fork or exec $HYBRID_SS, @args, $file1 or die $!;
	$exclB or my $pid5 = fork or exec $HYBRID_SS, @args, $file2 or die $!;
	waitpid $pid1, 0;
	waitpid $pid2, 0 unless $exclAA;
	waitpid $pid3, 0 unless $exclBB;
	waitpid $pid4, 0 unless $exclA;
	waitpid $pid5, 0 unless $exclB;
    } else {
	system($HYBRID, @args, $file1, $file2) == 0 or systemError($HYBRID);
	$exclAA or system($HYBRID, @args, $file1, $file1) == 0 or systemError($HYBRID);
	$exclBB or system($HYBRID, @args, $file2, $file2) == 0 or systemError($HYBRID);
	$exclA or system($HYBRID_SS, @args, $file1) == 0 or systemError($HYBRID_SS);
	$exclB or system($HYBRID_SS, @args, $file2) == 0 or systemError($HYBRID_SS);
    }
}

if ($options{infinity}) {
    unless ($exclA) {
	my $ZaInf;
	open IN, '<', "$prefix1.dG" or die $!;
	scalar <IN>;
	while (<IN>) {
	    my ($t, $g, $z) = split;
	    $ZaInf = $z unless defined $ZaInf and $ZaInf < $z;
		
	}
	close IN or die $!;
	open OUT, '>', "$prefix1.inf" or die $!;
	print OUT "$ZaInf\n";
	close OUT or die $!;
    }
    unless ($exclB) {
	my $ZbInf;
	open IN, '<', "$prefix2.dG" or die $!;
	scalar <IN>;
	while (<IN>) {
	    my ($t, $g, $z) = split;
	    $ZbInf = $z unless defined $ZbInf and $ZbInf < $z;
	    
	}
	open OUT, '>', "$prefix2.inf" or die $!;
	print OUT "$ZbInf\n";
	close OUT or die $!;
	close IN or die $!;
    }
    unless ($exclAA) {
	my $ZaaInf;
	open IN, '<', "$prefix1-$prefix1.dG" or die $!;
	scalar <IN>;
	while (<IN>) {
	    my ($t, $g, $z) = split;
	    $ZaaInf = $z unless defined $ZaaInf and $ZaaInf < $z;
		
	}
	close IN or die $!;
	open OUT, '>', "$prefix1-$prefix1.inf" or die $!;
	print OUT "$ZaaInf\n";
	close OUT or die $!;
    }
    unless ($exclBB) {
	my $ZbbInf;
	open IN, '<', "$prefix2-$prefix2.dG" or die $!;
	scalar <IN>;
	while (<IN>) {
	    my ($t, $g, $z) = split;
	    $ZbbInf = $z unless defined $ZbbInf and $ZbbInf < $z;
		
	}
	close IN or die $!;
 	open OUT, '>', "$prefix2-$prefix2.inf" or die $!;
	print OUT "$ZbbInf\n";
	close OUT or die $!;
   }
    my $ZabInf;
    open IN, '<', "$prefix1-$prefix2.dG" or die $!;
    scalar <IN>;
    while (<IN>) {
	my ($t, $g, $z) = split;
	$ZabInf = $z unless defined $ZabInf and $ZabInf < $z;
	
    }
    close IN or die $!;
	open OUT, '>', "$prefix1-$prefix2.inf" or die $!;
	print OUT "$ZabInf\n";
	close OUT or die $!;
}

if (defined $fraction) {
    my ($dHa, $dSa, $dHb, $dSb);
    if ($olddHss) {
	system('concentration', -A => $A0, -B => $B0, @concArgs, $prefix1, $prefix2) == 0 or systemError('concentration');
	system('ensemble-dg', @concArgs, $prefix1, $prefix2) == 0 or systemError('ensemble-dg');
	system('dG2dH', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dH');
	open IN, '<', "$prefix.ens.dH" or die $!;
	chomp($dH = <IN>);
	close IN or die $!;
	$dH *= -$fraction;
	$dHa = $dH * length($seq1) / (length($seq1) + length($seq2));
	$dHb = $dH * length($seq2) / (length($seq1) + length($seq2));
    } else {
	chomp($dHa = `sbs --NA=$options{NA} $file1`);
	chomp($dHb = `sbs --NA=$options{NA} $file2`);
	$dHa *= $fraction / 2.0;
	$dHb *= $fraction / 2.0;
    }
    $dSa = $dHa / ($tMelt + 273.15) * 1000.0;
    $dSb = $dHb / ($tMelt + 273.15) * 1000.0;
    push @concArgs, -H => "$dHa,$dHb", -S => "$dSa,$dSb";
}

system('concentration', -A => $A0, -B => $B0, @concArgs, $prefix1, $prefix2) == 0 or systemError('concentration');
system('concentrations.pl', "$prefix1-$prefix2") == 0 or systemError('concentrations.pl');
system('ensemble-dg', @concArgs, $prefix1, $prefix2) == 0 or systemError('ensemble-dg');
system('dG2Cp', '--points' => $points, "$prefix1-$prefix2.A.dG") == 0 or systemError('dG2Cp');
system('dG2Cp', '--points' => $points, "$prefix1-$prefix2.B.dG") == 0 or systemError('dG2Cp');
system('dG2Cp', '--points' => $points, "$prefix1-$prefix2.AA.dG") == 0 or systemError('dG2Cp');
system('dG2Cp', '--points' => $points, "$prefix1-$prefix2.BB.dG") == 0 or systemError('dG2Cp');
system('dG2Cp', '--points' => $points, "$prefix1-$prefix2.AB.dG") == 0 or systemError('dG2Cp');
system('dG2Cp', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2Cp');
system('dG2dH', '--points' => $points, "$prefix.A.dG") == 0 or systemError('dG2dH');
system('dG2dH', '--points' => $points, "$prefix.B.dG") == 0 or systemError('dG2dH');
system('dG2dH', '--points' => $points, "$prefix.AA.dG") == 0 or systemError('dG2dH');
system('dG2dH', '--points' => $points, "$prefix.BB.dG") == 0 or systemError('dG2dH');
system('dG2dH', '--points' => $points, "$prefix.AB.dG") == 0 or systemError('dG2dH');
system('dG2dH', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dH');
system('dG2dS', '--points' => $points, "$prefix.A.dG") == 0 or systemError('dG2dS');
system('dG2dS', '--points' => $points, "$prefix.B.dG") == 0 or systemError('dG2dS');
system('dG2dS', '--points' => $points, "$prefix.AA.dG") == 0 or systemError('dG2dS');
system('dG2dS', '--points' => $points, "$prefix.BB.dG") == 0 or systemError('dG2dS');
system('dG2dS', '--points' => $points, "$prefix.AB.dG") == 0 or systemError('dG2dS');
system('dG2dS', '--points' => $points, "$prefix.ens.dG") == 0 or systemError('dG2dS');
$options{energyOnly} or system('ensemble-ext', '--points' => $points, @concArgs, @extArgs, $file1, $file2) == 0 or systemError('ensemble-ext');
plot($seq1, $seq2);

sub sameSequence {
    my $tmp1 = lc $_[0];
    my $tmp2 = lc $_[1];
    $tmp1 =~ tr/t/u/;
    $tmp2 =~ tr/t/u/;

    print "Warning: sequences are the same\n" if $tmp1 eq $tmp2;
    $tmp1 eq $tmp2;
}

sub nss {
    my $tmp = lc $_[0];
    $tmp =~ tr/acgtu/ryryy/;
    my @chars = split //, $tmp;
    my $n = 0;
    for (my $i = 1; $i < @chars; ++$i) {
	if ($chars[$i - 1] eq 'r' and $chars[$i] eq 'r') {
	    $n += 1.0;
	} elsif ($chars[$i - 1] eq 'y' and $chars[$i] eq 'r') {
	    $n += 0.5;
	} elsif ($chars[$i - 1] eq 'r' and $chars[$i] eq 'y') {
	    $n += 0.5;
	}
    }
    return $n;
}

sub plot {
    my $LINEWIDTH = 2;
    my ($seq1, $seq2) = @_;

    open PLOT, '>', "$prefix.gp" or die $!;
    print PLOT "set terminal postscript enhanced color\n";
    print PLOT "set data style lines\n";
    print PLOT "set key left\n";
    print PLOT "set xlabel 'T ({/Symbol \\260}C)'\n";
    print PLOT "set xrange [$tmin_original:$tmax_original]\n";
    print PLOT "set yrange [0:]\n";

    my $TmConc;
    open TMCONC, '<', "$prefix.TmConc" or die $!;
    while (<TMCONC>) {
	($TmConc) = split;
    }
    close TMCONC or die $!;

    my ($TmCp, $Cp, $TmObs, $Obs);
    open TMCP, '<', "$prefix.ens.TmCp" or die $!;
    while (<TMCP>) {
	($TmCp, $Cp) = split;
    }
    close TMCP or die $!;
    if (-s "$prefix.obs.Tm") {
	open TM, '<', "$prefix.obs.Tm" or die $!;
	($TmObs, $Obs) = split /\t/, <TM>;
	close TM or die $!;
    }

    my ($TmExt, $Ext, $maxExt);
    unless ($options{energyOnly}) {
	open TMEXT, '<', "$prefix.ens.TmExt2" or die $!;
	($TmExt, $Ext) = split /\t/, <TMEXT>;
	close TMEXT or die $!;
	undef $TmExt if defined $TmExt and $TmExt eq 'nan';
	open MAXEXT, '<', "$prefix.ens.MaxExt" or die $!;
	chomp ($maxExt = <MAXEXT>);
	close MAXEXT or die $!;
    }

    my $TmCpString = defined $TmCp ? ", '$prefix.ens.TmCp' notitle w i lt 0 lw $LINEWIDTH" : '';
    my $TmExtString = defined $TmExt ? ", '$prefix.ens.TmExt2' notitle w i lt 0 lw $LINEWIDTH" : '';
    my $CpObsString = -s "$prefix.obs.Cp" ? ", '$prefix.obs.Cp' t 'Observed C_p' lt 2 lw $LINEWIDTH" : '';
    my $TmObsString = defined $TmObs ? ", '$prefix.obs.Tm' notitle w i lt 0 lw $LINEWIDTH" : '';

    if ($same) {
	if (defined $options{title}) {
	    print PLOT "set title '$options{title}'\n";
	} elsif (length($seq1) <= 60) {
	    print PLOT "set title '$seq1'\n";
	} else {
	    print PLOT "set title '$prefix1'\n";
	}
	print PLOT "set output '$prefix.Cp.ps'\n";
	print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	if ($options{energyOnly}) {
	    printf PLOT "set label 'T_mObs: %.1f' at %g,%g center\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString$CpObsString$TmObsString\n";
	} else {
	    print PLOT "plot '$prefix.ens.Cp' notitle lw $LINEWIDTH$TmCpString\n";
	}
	print PLOT "set nolabel 1\n" if defined $TmCp or (defined $options{energyOnly} and defined $TmObs);
	print PLOT "set nolabel 2\n" if defined $TmCp and defined $options{energyOnly} and defined $TmObs;
	print PLOT "set yrange [*:*]\n";
	print PLOT "set output '$prefix.Cp2.ps'\n";
	print PLOT "plot '$prefix1-$prefix1.A.Cp' t 'A' lw $LINEWIDTH, '$prefix1-$prefix1.AA.Cp' t 'AA' lw $LINEWIDTH, '$prefix.ens.Cp' t 'Ensemble' lw $LINEWIDTH\n";
	unless ($options{energyOnly}) {
	    print PLOT "set output '$prefix.ext.ps'\n";
	    print PLOT "set ylabel 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    printf PLOT "set label 'T_mExt: %.1f' at %g,%g right\n", $TmExt, $TmExt, $Ext * 1.02 if defined $TmExt;
	    print PLOT "set yrange [0:$maxExt]\n";
	    print PLOT "plot '$prefix.ens.ext' notitle lw $LINEWIDTH$TmExtString\n";
	    print PLOT "set nolabel 1\n" if defined $TmExt;
	    print PLOT "set output '$prefix.ext2.ps'\n";
	    print PLOT "plot '$prefix.A.ext' t 'A' lw $LINEWIDTH, '$prefix.AA.ext' t 'AA' lw $LINEWIDTH, '$prefix.ens.ext' t 'Ensemble' lw $LINEWIDTH\n";
	}
	print PLOT "set yrange [0:1]\n";
	print PLOT "set output '$prefix.conc.ps'\n";
	print PLOT "set ylabel 'M Fraction'\n";
	if (defined $TmConc) {
	    print PLOT "set arrow from $TmConc, graph 0 to $TmConc, graph 1 nohead lt 0 lw $LINEWIDTH\n";
	    printf PLOT "set label 'T_mConc: %.1f' at %g,%g left\n", $TmConc, $TmConc, 0.95;
	}
	print PLOT "plot '$prefix1-$prefix1.Au' t 'Au' lw $LINEWIDTH, '$prefix1-$prefix1.Af' t 'Af' lw $LINEWIDTH, '$prefix1-$prefix1.AA' t 'AA' lw $LINEWIDTH\n";
	if (defined $TmConc) {
	    print PLOT "set noarrow 1\n";
	    print PLOT "set nolabel 1\n";
	}
	if (-s "$prefix.obs.Cp" and not $options{energyOnly}) {
	    printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	    printf PLOT "set label 'T_mObs: %.1f' at %g,%g center\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    printf PLOT "set label 'T_mExt: %.1f' at second %g,%g right\n", $TmExt, $TmExt, $Ext * 1.02 if defined $TmExt;
	    print PLOT "set output '$prefix.obs.ps'\n";
	    print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	    print PLOT "set y2label 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    print PLOT "set yrange [0:*]\n";
	    print PLOT "set y2range [0:$maxExt]\n";
	    print PLOT "set y2tics\n";
	    print PLOT "set ytics nomirror\n";
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString, '$prefix.obs.Cp' lt 2 lw $LINEWIDTH$TmObsString, '$prefix.ens.ext' axes x1y2 lt 3 lw $LINEWIDTH";
	    print PLOT ", '$prefix.ens.TmExt2' axes x1y2 notitle w i lt 0 lw $LINEWIDTH" if defined $TmExt;
	    print PLOT "\n";
	} elsif (-s "$prefix.obs.ext") {
	    printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	    printf PLOT "set label 'T_mExt: %.1f' at second %g,%g right\n", $TmExt, $TmExt, $Ext / $maxExt * 1.02 if defined $TmExt;
	    printf PLOT "set label 'T_mObs: %.1f' at second %g,%g left\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    print PLOT "set output '$prefix.obs.ps'\n";
	    print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	    print PLOT "set y2label 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    print PLOT "set yrange [0:*]\n";
	    print PLOT "set y2range [0:1]\n";
	    print PLOT "set y2tics\n";
	    print PLOT "set ytics nomirror\n";
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString, '$prefix.ens.ext' u 1:(\$2/$maxExt) axes x1y2 title '$prefix.ens.ext' lt 2 lw $LINEWIDTH";
	    print PLOT ", '$prefix.ens.TmExt2' u 1:(\$2/$maxExt) axes x1y2 notitle w i lt 0 lw $LINEWIDTH" if defined $TmExt;
	    print PLOT ", '$prefix.obs.ext' axes x1y2 lt 3 lw $LINEWIDTH, '$prefix.obs.Tm' axes x1y2 notitle w i lt 0 lw $LINEWIDTH\n";
	}
    } else {
	if (defined $options{title}) {
	    print PLOT "set title '$options{title}'\n";
	} elsif (length($seq1) + length($seq2) <= 60) {
	    print PLOT "set title '$seq1 versus $seq2'\n";
	} elsif (length($seq1) <= 60 and length($seq2) <= length($seq1)) {
	    print PLOT "set title \"$seq1\\nversus $seq2\"\n";
	} elsif (length($seq2) <= 60 and length($seq1) <= length($seq2)) {
	    print PLOT "set title \"$seq1 versus\\n$seq2\"\n";
	} else {
	    print PLOT "set title '$prefix1 versus $prefix2'\n";
	}
	print PLOT "set output '$prefix.Cp.ps'\n";
	print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	if ($options{energyOnly}) {
	    printf PLOT "set label 'T_mObs: %.1f' at %g,%g center\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString$CpObsString$TmObsString\n";
	} else {
	    print PLOT "plot '$prefix.ens.Cp' notitle lw $LINEWIDTH$TmCpString\n";
	}
	print PLOT "set nolabel 1\n" if defined $TmCp or defined $TmObs;
	print PLOT "set nolabel 2\n" if defined $TmCp and defined $TmObs;
	print PLOT "set yrange [*:*]\n";
	print PLOT "set output '$prefix.Cp2.ps'\n";
	print PLOT "plot '$prefix1-$prefix2.A.Cp' t 'A' lw $LINEWIDTH, '$prefix1-$prefix2.B.Cp' t 'B' lw $LINEWIDTH, '$prefix1-$prefix2.AA.Cp' t 'AA' lw $LINEWIDTH, '$prefix1-$prefix2.BB.Cp' t 'BB' lw $LINEWIDTH, '$prefix1-$prefix2.AB.Cp' t 'AB' lw $LINEWIDTH, '$prefix.ens.Cp' t 'Ensemble' lw $LINEWIDTH\n";
	unless ($options{energyOnly}) {
	    print PLOT "set output '$prefix.ext.ps'\n";
	    print PLOT "set ylabel 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    printf PLOT "set label 'T_mExt: %.1f' at %g,%g right\n", $TmExt, $TmExt, $Ext * 1.02 if defined $TmExt;
	    print PLOT "set yrange [0:$maxExt]\n";
	    print PLOT "plot '$prefix.ens.ext' notitle lw $LINEWIDTH$TmExtString\n";
	    print PLOT "set nolabel 1\n" if defined $TmExt;
	    print PLOT "set output '$prefix.ext2.ps'\n";
	    print PLOT "plot '$prefix.A.ext' t 'A' lw $LINEWIDTH, '$prefix.B.ext' t 'B' lw $LINEWIDTH, '$prefix.AA.ext' t 'AA' lw $LINEWIDTH, '$prefix.BB.ext' t 'BB' lw $LINEWIDTH, '$prefix.AB.ext' t 'AB' lw $LINEWIDTH, '$prefix.ens.ext' t 'Ensemble' lw $LINEWIDTH\n";
	}
	print PLOT "set yrange [0:1]\n";
	print PLOT "set output '$prefix.conc.ps'\n";
	print PLOT "set ylabel 'M Fraction'\n";
	if (defined $TmConc) {
	    print PLOT "set arrow from $TmConc, graph 0 to $TmConc, graph 1 nohead lt 0 lw $LINEWIDTH\n";
	    printf PLOT "set label 'T_mConc: %.1f' at %g,%g left\n", $TmConc, $TmConc, 0.95;
	}
	print PLOT "plot '$prefix1-$prefix2.Au' t 'Au' lw $LINEWIDTH, '$prefix1-$prefix2.Bu' t 'Bu' lw $LINEWIDTH, '$prefix1-$prefix2.Af' t 'Af' lw $LINEWIDTH, '$prefix1-$prefix2.Bf' t 'Bf' lw $LINEWIDTH, '$prefix1-$prefix2.AA' t 'AA' lw $LINEWIDTH, '$prefix1-$prefix2.BB' t 'BB' lw $LINEWIDTH, '$prefix1-$prefix2.AB' t 'AB' lw $LINEWIDTH\n";
	if (defined $TmConc) {
	    print PLOT "set noarrow 1\n";
	    print PLOT "set nolabel 1\n";
	}
	if (-s "$prefix.obs.Cp" and not $options{energyOnly}) {
	    printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	    printf PLOT "set label 'T_mObs: %.1f' at %g,%g center\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    printf PLOT "set label 'T_mExt: %.1f' at second %g,%g right\n", $TmExt, $TmExt, $Ext * 1.02 if defined $TmExt;
	    print PLOT "set output '$prefix.obs.ps'\n";
	    print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	    print PLOT "set y2label 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    print PLOT "set yrange [0:*]\n";
	    print PLOT "set y2range [0:$maxExt]\n";
	    print PLOT "set y2tics\n";
	    print PLOT "set ytics nomirror\n";
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString, '$prefix.obs.Cp' t 'Observed C_p' lt 2 lw $LINEWIDTH$TmObsString, '$prefix.ens.ext' axes x1y2 t 'Computed Absorbance' lt 3 lw $LINEWIDTH";
	    print PLOT ", '$prefix.ens.TmExt2' axes x1y2 notitle w i lt 0 lw $LINEWIDTH" if defined $TmExt;
	    print PLOT "\n";
	} elsif (-s "$prefix.obs.ext") {
	    printf PLOT "set label 'T_mC_p: %.1f' at %g,%g center\n", $TmCp, $TmCp, $Cp * 1.02 if defined $TmCp;
	    printf PLOT "set label 'T_mExt: %.1f' at second %g,%g right\n", $TmExt, $TmExt, $Ext / $maxExt * 1.02 if defined $TmExt;
	    printf PLOT "set label 'T_mObs: %.1f' at second %g,%g left\n", $TmObs, $TmObs, $Obs * 1.02 if defined $TmObs;
	    print PLOT "set output '$prefix.obs.ps'\n";
	    print PLOT "set ylabel 'C_p (kcal / mol / K)'\n";
	    print PLOT "set y2label 'Absorbance (M^{-1} cm^{-1} {/Symbol \\264} 10^{-6})'\n";
	    print PLOT "set yrange [0:*]\n";
	    print PLOT "set y2range [0:1]\n";
	    print PLOT "set y2tics\n";
	    print PLOT "set ytics nomirror\n";
	    print PLOT "plot '$prefix.ens.Cp' t 'Computed C_p' lw $LINEWIDTH$TmCpString, '$prefix.ens.ext' u 1:(\$2/$maxExt) axes x1y2 t 'Computed Absorbance' lt 2 lw $LINEWIDTH";
	    print PLOT ", '$prefix.ens.TmExt2' u 1:(\$2/$maxExt) axes x1y2 notitle w i lt 0 lw $LINEWIDTH" if defined $TmExt;
	    print PLOT ", '$prefix.obs.ext' axes x1y2 t 'Observed Absorbance' lt 3 lw $LINEWIDTH, '$prefix.obs.Tm' axes x1y2 notitle w i lt 0 lw $LINEWIDTH\n";
	}
    }
    close PLOT or die $!;
    system('gnuplot', "$prefix.gp") == 0 or die ;
}
