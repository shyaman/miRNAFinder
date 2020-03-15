# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: largepseq.t,v 1.9 2001/11/02 18:48:09 jason Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

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
    plan tests => 22;
}
use Bio::Seq::LargePrimarySeq;
use Bio::Seq::LargeSeq;
use Bio::Location::Simple;
use Bio::Location::Fuzzy;
use Bio::Location::Split;

my $pseq = Bio::Seq::LargePrimarySeq->new();
ok $pseq;
$pseq->add_sequence_as_string('ATGGGGTGGGGTGAAACCCTTTGGGGGTGGGGTAAAT');
$pseq->add_sequence_as_string('GTTTGGGGTTAAACCCCTTTGGGGGGT');

ok $pseq->display_id('hello'), 'hello';

ok $pseq->seq, 'ATGGGGTGGGGTGAAACCCTTTGGGGGTGGGGTAAATGTTTGGGGTTAAACCCCTTTGGGGGGT' , "Sequence is " . $pseq->seq;

ok $pseq->subseq(3,7), 'GGGGT', "Subseq is ".$pseq->subseq(3,7);
my $location = new Bio::Location::Simple(-start => 4, -end => 8,
					 -strand => 1);
ok($pseq->subseq($location), 'GGGTG');

my $splitlocation = new Bio::Location::Split;

$splitlocation->add_sub_Location( new Bio::Location::Simple('-start' => 1,
							    '-end'   => 15,
							    '-strand' => 1));

$splitlocation->add_sub_Location( new Bio::Location::Simple('-start' => 21,
							    '-end'   => 27,
							    '-strand' => -1));

ok( $pseq->subseq($splitlocation), 'ATGGGGTGGGGTGAACCCCCAA');

my $fuzzy = new Bio::Location::Fuzzy(-start => '<10',
				     -end   => '18',
				     -strand => 1);

ok( $pseq->subseq($fuzzy), 'GGTGAAACC');


ok($pseq->trunc(8,15)->seq, 'GGGGTGAA', 
    'trunc seq was ' . $pseq->trunc(8,15)->seq);


ok $pseq->alphabet('dna'), 'dna'; # so translate will not complain
ok $pseq->translate()->seq, 'MGWGETLWGWGKCLGLNPFGG';


my $seq = new Bio::Seq::LargeSeq(-primaryseq => $pseq );

ok $seq->display_id('hello'), 'hello';

ok $seq->seq, 'ATGGGGTGGGGTGAAACCCTTTGGGGGTGGGGTAAATGTTTGGGGTTAAACCCCTTTGGGGGGT' , "Sequence is " . $seq->seq;

ok $seq->subseq(3,7), 'GGGGT', "Subseq is ".$seq->subseq(3,7);
ok ($seq->trunc(8,15)->seq, 'GGGGTGAA', 
    'trunc seq was ' . $seq->trunc(8,15)->seq);

ok $seq->alphabet('dna'), 'dna'; # so translate will not complain
ok $seq->translate()->seq, 'MGWGETLWGWGKCLGLNPFGG';

$seq = new Bio::Seq::LargeSeq( -display_id => 'hello');
$seq->seq('ATGGGGTGGGGT');
ok $seq->display_id, 'hello';

ok $seq->seq, 'ATGGGGTGGGGT' , "Sequence is " . $seq->seq;

ok $seq->subseq(3,7), 'GGGGT', "Subseq is ".$seq->subseq(3,7);
ok ($seq->trunc(8,12)->seq, 'GGGGT', 
    'trunc seq was ' . $seq->trunc(8,12)->seq);

ok $seq->alphabet('dna'), 'dna'; # so translate will not complain
ok $seq->translate()->seq, 'MGWG';
