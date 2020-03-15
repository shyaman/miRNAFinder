#! /usr/bin/perl -w

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

use constant HTML_HEAD1 => qq[<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<style type="text/css">
 body { background-color: \#ffffcc; font-family : Verdana, Tahoma, Arial, sans-serif; font-size : 10pt }
 h1 { font-size: 16pt; font-weight: bold }
</style>
];
use constant HTML_HEAD2 => qq[</head>\n<body>\n];
use constant HTML_FOOT => qq[</body>\n</html>\n];

use constant R => 0.0019872;

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
Usage: UNAFold.pl [options] file [file]

Options:
-V, --version
-h, --help
-n, --NA=(RNA | DNA) (defaults to RNA)
-t, --temp=<temperature> (defaults to 37)
-N, --sodium=<[Na+] in M> (defaults to 1)
-M, --magnesium=<[Mg++] in M> (defaults to 0)
-p, --polymer
-C, --Ct=<total strand concentration>
-I, --noisolate
-m, --maxbp=<maximum basepair distance>
-c, --constraints=<name of constraints file> (defaults to prefix.aux)
-P, --percent=<energy increment percent> (defaults to 5)
-W, --window=<window size> (default set by sequence length)
-X, --max=<maximum number of foldings> (defaults to 100)
    --ann=(none | p-num | ss-count) (defaults to none)
    --mode=(auto | bases | lines) (defaults to auto)
    --label=<base numbering frequency>
    --rotate=<structure rotation angle>
    --run-type=(text | html) (defaults to text)
    --model=(EM | PF) (defaults to EM)
    --circular
Obscure options:
    --allpairs
    --maxloop=<maximum bulge/interior loop size> (defaults to 30)
    --nodangle
    --simple
    --prefilter=<filter value>

EOF
print 'Report bugs to markhn@rpi.edu', "\n";
    exit;
}

my %extensions;
sub checkProgram ($) {
    print "Checking for $_[0]... ";
    if (eval { no warnings; open IN, '-|', $_[0], '--help' }) {
	print 'found, supports Postscript';
	while (<IN>) {
	    if (/\| gif/ or /\[ -g /) {
		$extensions{$_[0]}{gif} = 1;
		print ', GIF';
	    }
	    if (/\| jpeg/ or /\[ -jpg /) {
		$extensions{$_[0]}{jpg} = 1;
		print ', JPEG';
	    }
	    if (/\| png/ or /\[ -png /) {
		$extensions{$_[0]}{png} = 1;
		print ', PNG';
	    }
	}
	close IN;
	print "\n";
    } else {
	print "not found\n";
	return 0;
    }
    return 1;
}

sub checkProgram2 ($) {
    print "Checking for $_[0]... ";
    if (eval { no warnings; open IN, "$_[0] 2>&1 |" }) {
	close IN;
	print "found\n";
	return 1;
    } else {
	print "not found\n";
	return 0;
    }
}

sub parseSeq ($) {
    my ($name, $sequence) = ('', '');
    open IN, '<', $_[0] or die $!;
    while (<IN>) {
	chomp;
	next if /^\s+$/;
	if (/^>/) {
	    last if $sequence;
	    ($name = $_) =~ s/^>//;
	} elsif (/;/) {
	    $sequence .= (split ';')[0];
	    last;
	} else {
	    $sequence .= $_;
	}
    }
    close IN or die $!;
    unless ($name) {
	($name = $_[0]) =~ s/\.seq$//;
    }
    return ($name, $sequence)
}

sub saveStdOutErr($) {
    open my $oldout, '>&', STDOUT or die $!;
    open my $olderr, '>&', STDERR or die $!;
    open STDOUT, '>>', $_[0] or die $!;
    open STDERR, '>&', STDOUT or die $!;
    return ($oldout, $olderr);
}

sub restoreStdOutErr($$) {
    open STDERR, '>&', $_[1] or die $!;
    open STDOUT, '>&', $_[0] or die $!;
}

my ($model, $temp, $p, $w, $max, $ann, $mode, $rotate, $runtype, $label, %rules, $Ct, %options) = ('EM', undef, 5, -1, undef, 'none', 'auto', 0, 'text');
GetOptions \%options, 'version|V' => sub { version('UNAFold.pl') }, 'help|h' => sub { usage() }, 'NA|n=s' => \$rules{NA}, 'temp|t=f' => \$temp, 'allpairs', 'sodium|N=f'=> \$rules{sodium}, 'magnesium|M=f' => \$rules{magnesium}, 'polymer|p' => \$rules{polymer}, 'Ct|C=f' => \$Ct, 'noisolate|I', 'maxbp|m=i', 'constraints|c:s', 'circular' => \$rules{circular}, 'percent|P=f' => \$p, 'window|W=i' => \$w, 'max|X=i' => \$max, 'ann=s' => \$ann, 'mode=s' => \$mode, 'label=i' => \$label, 'rotate=i' => \$rotate, 'run-type=s' => \$runtype, 'maxloop=i', 'nodangle' => \$rules{nodangle}, 'simple' => \$rules{nodangle}, 'prefilter=s', 'model=s' => \$model or die $!;

my @rules;
if (defined $temp or defined $rules{NA}) {
    defined $temp or $temp = 37;
    defined $rules{NA} or $rules{NA} = 'RNA';
    @rules = ('--NA' => $rules{NA}, '--tmin' => $temp, '--tmax' => $temp);
    push @rules, '--sodium' => $rules{sodium} if defined $rules{sodium};
    push @rules, '--magnesium' => $rules{magnesium} if defined $rules{magnesium};
    push @rules, ' --polymer' if $rules{polymer};
} else {
    @rules = ('--suffix' => 'DAT');
    $temp = 37;
}
my @rules2;
foreach ('allpairs', 'circular', 'nodangle', 'simple') {
    push @rules2, "--$_" if $rules{$_};
}
my @command;
if ($model eq 'PF') {
    defined $max or $max = 10;
    @command = ('hybrid-ss', @rules, @rules2, '--tracebacks'=> $max);
} else {
    defined $max or $max = 100;
    @command = ('hybrid-ss-min', @rules, @rules2, "--mfold=$p,$w,$max");
}
if (@rules >= 6 and $rules[2] eq '--tmin') {
    my $temperature = $rules[3];
    splice @rules, 2, 4, '--temperature' => $temperature;
}

foreach (keys %options) {
    if ($_ eq 'noisolate') {
	push @command, "--$_";
    } else {
	push @command, "--$_";
	push @command, $options{$_} if defined $options{$_};
    }
}

unless (@ARGV) {
    print STDERR "Error: data not specified\nRun 'UNAFold.pl -h' for help\n";
    exit 1;
}

my $file1 = shift;
my $prefix = basename $file1, '.seq';
push @command, $file1;

my ($name1, $sequence1) = parseSeq($file1);
$sequence1 =~ tr/A-Za-z0-9//cd;
my $length = length $sequence1;

my $title;
if (@ARGV) {
    unless (defined $Ct) {
	die "Error: two files found but no strand concentration given\n";
    }

    my $file2 = shift;
    $prefix .= '-' . basename $file2, '.seq';
    $command[0] =~ s/^hybrid-ss/hybrid/;
    push @command, $file2;
    my ($name2, $sequence2) = parseSeq($file2);
    $sequence2 =~ tr/A-Za-z0-9//cd;
    $length += length $sequence2;
    $title = "Hybridizing $name1 and $name2";
} else {
    undef $Ct;
    $title = "Folding $name1";
}

my $boxplot = checkProgram 'boxplot_ng';
my $hybridplot = checkProgram 'hybrid-plot-ng';
my $sirgraph = checkProgram 'sir_graph_ng';
my $ps2pdfwr = checkProgram2 'ps2pdfwr';

my $ctName = $prefix;
$ctName .= ".$temp" if $model eq 'PF';
$ctName .= '.ct';

system(@command) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from $command[0]\n");
unless ($model eq 'PF') {
    system('h-num.pl', $prefix) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from h-num.pl\n");
}
open my $oldout, '>&', STDOUT or die $!;
open STDOUT, '>', "$prefix.ss-count" or die $!;
system('ss-count.pl', $ctName) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from ss-count.pl\n");
open STDOUT, '>&', $oldout or die $!;

my (@dH, @dS, @Tm);
unless ($rules[0] eq '--suffix') {
    my $suffix = ($rules{NA} eq 'DNA') ? 'DHD' : 'DH';
    open IN, '-|', 'ct-energy', '--suffix' => $suffix, @rules2, $ctName or die $!;
    while (<IN>) {
	chomp;
	push @dH, $_;
    }
    close IN or die $!;
}

# Check each pair to determine if it's a homo- or heterodimer.
my @homo;
if (defined $Ct) {
    open IN, '<', "$prefix.ct" or die $!;
    while (<IN>) {
	my ($len) = /(\d+)\sdG = [^\s]+/ or next;
	my $homo = not ($len % 2);
	my @bases;
	for (my $i = 1; $i <= $len; ++$i) {
	    my $line = scalar <IN>;
	    my (undef, $base, $prev, $next) = split /\s+/, $line;
	    if (($i == $len / 2 and $next) or ($i == $len / 2 + 1 and $prev)) {
		$homo = 0;
	    }
	    if ($i <= $len / 2) {
		push @bases, $base;
	    } else {
		$homo = 0 unless @bases and $base eq shift @bases;
	    }
	}
	push @homo, $homo;
    }
    close IN or die $!;
}

my $detfile = $runtype eq 'html' ? "$prefix.det.html" : "$prefix.det";
open OUT, '>', $detfile or die $!;
if ($runtype eq 'html') {
    print OUT HTML_HEAD1;
    print OUT "<title>Loop Free-Energy Decomposition</title>\n";
    print OUT HTML_HEAD2;
    print OUT "<h1>Loop Free-Energy Decomposition</h1>\n";
}
open DET, "ct-energy @rules --verbose '$ctName' | ct-energy-det.pl --mode $runtype |" or die $!;
my ($det, @dG);
my $i = 1;
while (<DET>) {
    if (/<!-- Structure \d+ energy = (.+) -->/ or /^([0-9.e+-]+)$/) {
	my $dG = $1;
	unless ($i == 1) {
	    print OUT "\n" if $runtype ne 'html';
	}
	my ($dS, $Tm);
	if (@dH) {
	    $dS = 1000.0 * ($dH[$i - 1] - $dG) / (273.15 + $temp);
	    if (defined $Ct) {
		my $factor = shift @homo ? 1 : 4;	    
		$Tm = 1000.0 * $dH[$i - 1] / ($dS + 1000.0 * R * log($Ct / $factor)) - 273.15;
	    } else {
		$Tm = 1000.0 * $dH[$i - 1] / $dS - 273.15;
	    }
	    push @dS, $dS;
	    push @Tm, $Tm;
	}
	if ($runtype eq 'html') {
	    print OUT "<p><a name=\"Structure_$i\">Structure $i</a>: ";
	    printf OUT "&Delta;G = %+.2f", $dG;
	    printf OUT " &nbsp; &Delta;H = %+.2f &nbsp; &Delta;S = %+.2f &nbsp; T<sub>m</sub> = %.1f", $dH[$i - 1], $dS, $Tm if @dH;
	    print OUT "</p>\n";
	} else {
	    print OUT "Structure $i: ";
	    printf OUT "dG = %+.2f", $dG;
	    printf OUT "  dH = %+.2f  dS = %+.2f  Tm = %.1f", $dH[$i - 1], $dS, $Tm if @dH;
	    print OUT "\n\n";
	}
	print OUT $det;
	$det = '';
	push @dG, $dG;
	++$i;
    } else {
	$det .= $_;
    }
}
close DET or die $!;
if ($runtype eq 'html') {
    print OUT HTML_FOOT;
}
close OUT or die $!;

if ($model eq 'PF' and $hybridplot) {
    my @command = ('hybrid-plot-ng', '--temperature' => $temp);
    if ($extensions{'hybrid-plot-ng'}{png}) {
	push @command, '--format' => 'png';
    } elsif ($extensions{'hybrid-plot-ng'}{jpg}) {
	push @command, '-format' => 'jpeg';
    } elsif ($extensions{'hybrid-plot-ng'}{gif}) {
	push @command, '--format' => 'gif';
    }
    my $degree = chr 176;
    my ($oldout, $olderr) = saveStdOutErr("$prefix.log");
    push @command, '--title' => "$title at $temp${degree}C.", $prefix;
    system(@command) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from hybrid-plot-ng\n");
    if ($command[2] eq '--format') {
	splice @command, 2, 2;
	system(@command) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from hybrid-plot-ng\n");
    }
    restoreStdOutErr($oldout, $olderr);
    print "Probability dot plot created.\n";
} elsif ($model ne 'PF' and $boxplot) {
    my @command = ('boxplot_ng', '-d', -c => 4);
    if ($extensions{boxplot_ng}{png}) {
	push @command, '-png ', '-pg', -r => 72;
    } elsif ($extensions{boxplot_ng}{jpg}) {
	push @command, '-jpg', '-pg', -r => 72;
    } elsif ($extensions{boxplot_ng}{gif}) {
	push @command, '-g', '-pg', -r => 72;
    }
    my $degree = chr 176;
    my ($oldout, $olderr) = saveStdOutErr("$prefix.log");
    push @command, -t => "$title at $temp${degree}C.", $prefix;
    system(@command) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from boxplot_ng\n");
    restoreStdOutErr($oldout, $olderr);
    print "Energy dot plot created.\n";
}

my $img;
if ($extensions{sir_graph_ng}{png}) {
    $img = '-png';
} elsif ($extensions{sir_graph_ng}{jpg}) {
    $img = '-jpg';
} elsif ($extensions{sir_graph_ng}{gif}) {
    $img = '-g';
}

unless (defined $label) {
    if ($length <= 50) {
	$label = 10;
    } elsif ($length <= 300) {
	$label = 20;
    } else {
	$label = 50;
    }
}

my $ann_type;
if ($mode eq 'bases') {
    $ann_type = 'character';
} elsif ($mode eq 'lines') {
    $ann_type = 'dot';
} elsif ($mode eq 'auto') {
    if ($length < 800) {
	$mode = 'bases';
    } else {
	$mode = 'lines';
    }
    if ($mode eq 'bases') {
	$ann_type = 'both';
    } else {
	$ann_type = 'dot';
    }
}

my @flags;
if ($ann eq 'none') {
    if ($mode eq 'lines') {
	@flags = ('-outline');
    }
} elsif ($ann eq 'p-num') {
    @flags = ('-pnum');
    if ($ann_type eq 'character') {
	push @flags, '-ab';
    } elsif ($ann_type eq 'dot') {
	push @flags, '-ad';
    }
} elsif ($ann eq 'ss-count') {
    @flags = '-ss-count';
    if ($ann_type eq 'character') {
	push @flags, '-ab';
    } elsif ($ann_type eq 'dot') {
	push @flags, '-ad';
    }
}

push @flags, -lab => $label;
push @flags, -rot => $rotate;

my @dGnew;
if ($rules[0] eq 'suffix') {
    open IN, '-|', 'ct-energy', @rules, @rules2, '--logarithmic', $ctName or die $!;
    while (<IN>) {
	chomp;
	push @dGnew, sprintf '%+.2f', $_;
    }
    close IN or die $!;
}

my $fold = 1;
open IN, '<', $ctName or die $!;
while (<IN>) {
    open OUT, '>', "${prefix}_$fold.ct" or die $!;
    my $length = (split)[0];
    s/dG = ([^ \t]+)/dG = $dGnew[$fold-1] [initially $1]/ if @dGnew;
    print OUT;
    for (my $i = 0; $i < $length; ++$i) {
	print OUT scalar <IN>;
    }
    close OUT or die $!;

    if ($sirgraph) {
	system('sir_graph_ng', @flags, -ss => "${prefix}_$fold") == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from sir_graph_ng\n");
	my ($oldout, $olderr) = saveStdOutErr("$prefix.log");
	system('sir_graph_ng', @flags, -p => "${prefix}_$fold") == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from sir_graph_ng\n");
	if ($img) {
	    system('sir_graph_ng', @flags, $img, "${prefix}_$fold") == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from sir_graph_ng\n");
	}
	restoreStdOutErr($oldout, $olderr);
	if ($ps2pdfwr) {
	    system('ps2pdfwr', "${prefix}_$fold.ps") == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from ps2pdfwr\n");
	}
    }
    ++$fold;
}
close IN or die $!;
print "Structure plots generated.\n" if $sirgraph;

unless ($model eq 'PF') {
	system('ct2rnaml', $prefix) == 0 or die ($? == -1 ? $! : 'Exit status ' . ($? >> 8) . " from ct2rnaml\n");
}

if ($runtype eq 'html') {
    my $plotPrefix = $model eq 'PF' ? "$prefix.$temp" : $prefix;
    open OUT, '>', "$prefix.html" or die $!;
    print OUT HTML_HEAD1;
    print OUT "<title>Results of $title</title>\n";
    print OUT HTML_HEAD2;
    print OUT "<h1>$title at $temp&deg;C</h1>\n";
    print OUT "<p>The ", ($model eq 'PF' ? 'probability' : 'energy'), " dot plot: <a href=\"$plotPrefix.plot\">Text</a>";
    print OUT ", <a href=\"$plotPrefix.ps\">Postscript</a>" if -e "$plotPrefix.ps";
    print OUT ", <a href=\"$plotPrefix.png\">PNG</a>" if -e "$plotPrefix.png";
    print OUT ", <a href=\"$plotPrefix.jpg\">JPEG</a>" if -e "$plotPrefix.jpg";
    print OUT ", <a href=\"$plotPrefix.gif\">GIF</a>" if -e "$plotPrefix.gif";
    print OUT "</p>\n";
    print OUT "<p>Computed structures:";
    print OUT " <a href=\"$prefix.rnaml\">RNAML</a>" unless $model eq 'PF';
    print OUT "</p>\n<ul>\n";
    for (my $i = 1; $i < $fold; ++$i) {
	if (@dH) {
	    printf OUT "<li>Structure $i: &Delta;G = %+.2f &nbsp; &Delta;H = %+.2f &nbsp; &Delta;S = %+.2f &nbsp; T<sub>m</sub> = %.1f&deg;\n", $dG[$i - 1], $dH[$i - 1], $dS[$i - 1], $Tm[$i - 1];
	} else {
	    printf OUT "<li>Structure $i: &Delta;G = %+.2f\n", $dG[$i - 1];
	}
	print OUT "<ul>\n";
	print OUT "<li><a href=\"$prefix.det.html#Structure_$i\">Thermodynamic details</a></li>\n";
	print OUT "<li><a href=\"${prefix}_$i.ct\">.ct file</a>";
	print OUT ", <a href=\"${prefix}_$i.ps\">Postscript</a>" if -e "${prefix}_$i.ps";
	print OUT ", <a href=\"${prefix}_$i.pdf\">PDF</a>" if -e "${prefix}_$i.pdf";
	print OUT ", <a href=\"${prefix}_$i.png\">PNG</a>" if -e "${prefix}_$i.png";
	print OUT ", <a href=\"${prefix}_$i.jpg\">JPEG</a>" if -e "${prefix}_$i.jpg";
	print OUT ", <a href=\"${prefix}_$i.gif\">GIF</a>" if -e "${prefix}_$i.gif";
	print OUT ", <a href=\"${prefix}_$i.ss\">XRNA ss</a>" if -e "${prefix}_$i.ss";
	print OUT "</li>\n";
	print OUT "</ul>\n";
	print OUT "</li>\n";
    }
    print OUT "</ul>\n";
    print OUT HTML_FOOT;
    close OUT or die $!;
}
