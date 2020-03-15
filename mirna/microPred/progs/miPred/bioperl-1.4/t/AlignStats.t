# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: AlignStats.t,v 1.6 2003/10/16 14:15:44 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

my $error = 0;

use strict;
BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
	use lib 't';
    }

    use Test;
    plan tests => 21; 
}

if( $error == 1 ) {
    exit(0);
}

my $debug = -1;

use Bio::Align::DNAStatistics;
use Bio::AlignIO;
use Bio::Root::IO;

# NOTE NOTE NOTE
# A lot more work needs to be done on this DNAStatistics object
# it currently doesn't actually calculate everything correctly
# The currently implemented tests show what DOES work.
# Volunteers welcomed

my $in = new Bio::AlignIO(-format => 'emboss',
			  -file   => Bio::Root::IO->catfile('t', 'data',
							    'insulin.water'));
my $aln = $in->next_aln();
ok($aln);
my $stats = new Bio::Align::DNAStatistics(-verbose => $debug);
ok( $stats->transversions($aln),4);
ok( $stats->transitions($aln),9);
ok( $stats->pairwise_stats->number_of_gaps($aln),21);
ok( $stats->pairwise_stats->number_of_comparable_bases($aln),173);
ok( $stats->pairwise_stats->number_of_differences($aln),13);

my $d = $stats->distance(-align=> $aln,
			 -method => 'JC');
ok( sprintf("%.5f",$d->[1]->[2]), 0.07918);
$d = $stats->distance(-align=> $aln,
			 -method => 'Kimura');
ok( sprintf("%.5f",$d->[1]->[2]), 0.07984);
#$d = $stats->distance(-align=> $aln,
#			 -method => 'TajimaNei');

#ok( sprintf("%.5f",$d->[1]->[2]), 0.0780);

$aln = $in->next_aln();
ok(! defined $aln);

$in = new Bio::AlignIO(-format => 'fasta',
		       -file   => Bio::Root::IO->catfile('t','data',
							 'hs_owlmonkey.fasta'));

$aln = $in->next_aln();
ok($aln);

ok( $stats->transversions($aln),4);
ok( $stats->transitions($aln),14);
ok( $stats->pairwise_stats->number_of_gaps($aln),33);
ok( $stats->pairwise_stats->number_of_comparable_bases($aln),163);
ok( $stats->pairwise_stats->number_of_differences($aln),18);

# now test the distance calculations
if( 0 ) {
    $d = $stats->distance(-align => $aln, -method => 'jc');
    ok( sprintf("%.4f", $d->[1]->[2]), 0.1195);

    $d =  $stats->distance(-align => $aln,
			   -method => 'Kimura');
    ok( sprintf("%.4f", $d->[1]->[2]), 0.1219);

#    $d =  $stats->distance(-align => $aln,
#			   -method => 'TajimaNei');
#    ok( sprintf("%.4f", $d->[1]->[2]), 0.1246);
}
#ok( sprintf("%.4f", Bio::Align::DNAStatistics->D_JukesCantorInCor($aln)), 0.1104);

#ok( sprintf("%.4f", Bio::Align::DNAStatistics->D_Tamura($aln)), 0.1233);
#ok( sprintf("%.4f", Bio::Align::DNAStatistics->D_Tamura($aln)), 0.1246);
#ok( sprintf("%.4f", Bio::Align::DNAStatistics->D_JinNeiGamma($aln)), 0.1350);

### now test Nei_gojobori methods ##
$in = Bio::AlignIO->new(-format => 'fasta',
		       -file   => Bio::Root::IO->catfile('t','data', 'nei_gojobori_test.aln'));
my $alnobj = $in->next_aln();
ok($alnobj);
my $result = $stats->calc_KaKs_pair($alnobj, 'seq1', 'seq2');
ok (sprintf ("%.1f", $result->[0]{'S'}), 40.5);
ok (sprintf ("%.1f", $result->[0]{'z_score'}), '4.5');
$result = $stats->calc_all_KaKs_pairs($alnobj);
ok (int( $result->[1]{'S'}), 41);
ok (int( $result->[1]{'z_score'}), 4);
$result = $stats->calc_average_KaKs($alnobj, 100);
ok (sprintf ("%.4f", $result->{'D_n'}), 0.1628);


