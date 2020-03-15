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

my $helix = 0.0;
my $length = 1;
my $mode = 'text';
my $structure = 1;

sub cp ($$$$) {
    if ($mode eq 'html') {
	return "<a name=\"Structure_${structure}_$_[1]_$_[3]\">Closing pair is $_[0]<sup>$_[1]</sup>-$_[2]<sup>$_[3]</sup></a>";
    } else {
	return sprintf 'Closing pair is %s(%6d)-%s(%6d)', $_[0], $_[1], $_[2], $_[3];
    }
}

sub ecp ($$$$) {
    if ($mode eq 'html') {
	return "<a name=\"Structure_${structure}_$_[1]_$_[3]\">External closing pair is $_[0]<sup>$_[1]</sup>-$_[2]<sup>$_[3]</sup></a>";
    } else {
	return sprintf 'External closing pair is %s(%6d)-%s(%6d)', $_[0], $_[1], $_[2], $_[3];
    }
}

sub helix () {
    if ($helix) {
	if ($mode eq 'html') {
	    printf " <tr><th>Helix</th><td align=\"right\">%+.2f</td><td>$length base pairs</td></tr>\n", $helix;
	} else {
	    printf "Helix:           ddG = %+6.2f $length base pairs.\n", $helix;
	}
    }
    $helix = 0.0;
    $length = 1;
}

sub usage () {
    print <<EOF;
Usage: ct-energy-det.pl [options] [files]

Options:
-V, --version
-h, --help
-m, --mode=(text | html) (defaults to text)

EOF
    print 'Report bugs to markhn@rpi.edu', "\n";
    exit;
}

GetOptions 'version|V' => sub { version('ct-energy-det.pl') }, 'help|h' => sub { usage() }, 'mode|m=s' => \$mode or die $!;

print "<table border=\"1\">\n" if $mode eq 'html';
print " <tr><th>Structural element</th><th>&delta;&delta;G</th><th>Information</th></tr>\n" if $mode eq 'html';
my $inTable = 1;
while (<>) {
    chomp;

    if (/Energy = (.+)$/) {
	if ($mode eq 'html') {
	    print "</table>\n";
	    print "<!-- Structure $structure energy = $1 -->\n";
	} else {
	    print "$1\n";
	}
	$inTable = 0;
	++$structure;
	next;
    }

    unless ($inTable) {
	print "<table border=\"1\">\n" if $mode eq 'html';
	print " <tr><th>Structural element</th><th>&delta;&delta;G</th><th>Information</th></tr>\n" if $mode eq 'html';
	$inTable = 1;
    }

    my ($type, $info, $dG) = split ': ';
    defined $info or next;

    # Not all versions of Perl understand 'inf' as infinity automatically.
    $dG = 1e999 if $dG =~ /inf/;

    if ($type eq 'Exterior') {
	$type = 'External loop';
	if (my ($ss, $ds) = $info =~ /(\d+) ss, (\d+) ds/) {
	    $info = "$ss ss bases " . ($mode eq 'html' ? '&amp;' : '&') ." $ds closing helices";
	} else {
	    my ($i, $a, $j, $b) = $info =~ /^(\d+)-(.) (\d+)-(.)/;
	    $info = cp($a, $i, $b, $j);
	}
	helix();
    } elsif ($type eq 'Hairpin') {
	$type = 'Hairpin loop';
	my ($i, $a, $j, $b) = $info =~ /^(\d+)-(.) (\d+)-(.)/;
	$info = cp($a, $i, $b, $j);
	helix();
    } elsif ($type eq 'Stack' or $type eq 'Bulge' or $type eq 'Interior') {
	$type = 'Bulge loop' if $type eq 'Bulge';
	$type = 'Interior loop' if $type eq 'Interior';
	my ($i, $a, $j, $b) = $info =~ /^(\d+)-(.) (\d+)-(.)/;
	$info = ecp($a, $i, $b, $j);
	if ($type eq 'Stack') {
	    $helix += $dG;
	    ++$length;
	} else {
	    helix();
	}
    } elsif ($type eq 'Multi') {
	$type = 'Multi-loop';
	my ($i, $a, $j, $b, $ss, $ds) = $info =~ /^(\d+)-(.) (\d+)-(.), (\d+) ss, (\d+) ds/;
	$info = ecp($a, $i, $b, $j);
	if ($mode eq 'html') {
	    $info .= "<br />$ss ss bases &amp; $ds closing helices";
	} else {
	    $info .= sprintf "\n                              $ss ss bases & $ds closing helices.", $i, $j;
	}
	helix();
    }

    if ($mode eq 'html') {
	printf " <tr><td>$type</td><td align=\"right\">%+.2f</td><td>$info</td></tr>\n", $dG;
    } else {
	printf "%-14s   ddG = %+6.2f $info\n", "$type:", $dG;
    }
}
