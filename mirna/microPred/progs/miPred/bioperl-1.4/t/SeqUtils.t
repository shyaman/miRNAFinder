# -*-Perl-*-
## Bioperl Test Harness Script for Modules
##$Id: SeqUtils.t,v 1.13 2003/08/12 20:16:48 jason Exp $

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

use Bio::PrimarySeq;
use Bio::SeqUtils;
use Bio::LiveSeq::Mutation;
ok 1;

my ($seq, $util, $ascii, $ascii_aa, $ascii3);

#                     !    !          
$ascii =    'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
$ascii_aa = 'ABCDEFGHIXKLMNXPQRSTUVWXYZ';

$ascii3 = 
    'AlaAsxCysAspGluPheGlyHisIleXaaLysLeuMetAsnXaaProGlnArgSerThrSecValTrpXaaTyrGlx';

$seq = Bio::PrimarySeq->new('-seq'=> $ascii,
			    '-alphabet'=>'protein', 
			       '-id'=>'test');

# one letter amino acid code to three letter code
ok $util = new Bio::SeqUtils;
ok $util->seq3($seq), $ascii3;

#using anonymous hash
ok (Bio::SeqUtils->seq3($seq), $ascii3); 
ok (Bio::SeqUtils->seq3($seq, undef, ','), 
    'Ala,Asx,Cys,Asp,Glu,Phe,Gly,His,Ile,Xaa,Lys,'.
    'Leu,Met,Asn,Xaa,Pro,Gln,Arg,Ser,Thr,Sec,Val,Trp,Xaa,Tyr,Glx');

$seq->seq('asd-KJJK-');
ok (Bio::SeqUtils->seq3($seq, '-', ':'), 
    'Ala:Ser:Asp:Ter:Lys:Xaa:Xaa:Lys:Ter');

# three letter amino acid code to one letter code
ok (Bio::SeqUtils->seq3in($seq, 'AlaPYHCysAspGlu')), 
ok  $seq->seq, 'AXCDE';
ok (Bio::SeqUtils->seq3in($seq, $ascii3)->seq, $ascii_aa);
#ok ();

#
# Tests for multiframe translations
#

$seq = Bio::PrimarySeq->new('-seq'=> 'agctgctgatcggattgtgatggctggatggcttgggatgctgg',
			    '-alphabet'=>'dna', 
			    '-id'=>'test2');

my @a = $util->translate_3frames($seq);
ok scalar @a, 3;
#foreach $a (@a) {
#    print 'ID: ', $a->id, ' ', $a->seq, "\n";
#}

@a = $util->translate_6frames($seq);
ok scalar @a, 6;
#foreach $a (@a) {
#    print 'ID: ', $a->id, ' ', $a->seq, "\n";
#}

#
# test for valid AA return
#

my @valid_aa = sort Bio::SeqUtils->valid_aa;
ok(@valid_aa, 25);
ok ($valid_aa[1], 'A');

@valid_aa = sort Bio::SeqUtils->valid_aa(1);
ok(@valid_aa, 25);
ok ($valid_aa[1], 'Arg');

my %valid_aa = Bio::SeqUtils->valid_aa(2);
ok keys %valid_aa, 50;
ok($valid_aa{'C'}, 'Cys');
ok( $valid_aa{'Cys'}, 'C');


#
# Mutate
#

my $string1 = 'aggt';
$seq = Bio::PrimarySeq->new('-seq'=> 'aggt',
			    '-alphabet'=>'dna',
			    '-id'=>'test3');

# point
Bio::SeqUtils->mutate($seq,
                      Bio::LiveSeq::Mutation->new(-seq => 'c',
                                                  -pos => 3
                                                 )
                     );
ok $seq->seq, 'agct';

# insertion and deletion
my @mutations = (
                 Bio::LiveSeq::Mutation->new(-seq => 'tt',
                                             -pos => 2,
                                             -len => 0
                                            ),
                 Bio::LiveSeq::Mutation->new(-pos => 2,
                                             -len => 2
                                            )
);

Bio::SeqUtils->mutate($seq, @mutations);
ok $seq->seq, 'agct';

# insertion to the end of the sequence
Bio::SeqUtils->mutate($seq,
                      Bio::LiveSeq::Mutation->new(-seq => 'aa',
                                                  -pos => 5,
                                                  -len => 0
                                                 )
                     );
ok $seq->seq, 'agctaa';
