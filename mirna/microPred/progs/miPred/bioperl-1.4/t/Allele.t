# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: Allele.t,v 1.6 2001/10/22 08:22:58 heikki Exp $

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
    plan tests => 15 }

use Bio::Variation::Allele;

ok(1);

my($a,$trunc,$rev);

$a = Bio::Variation::Allele->new(-seq=>'ACTGACTGACTG',
			-display_id => 'new-id',
			-alphabet => 'dna',
			-accession_number => 'X677667',
                        -desc=>'Sample Bio::Seq object');
ok defined $a,
ok ref($a), 'Bio::Variation::Allele';

ok $a->accession_number(), 'X677667';
ok $a->seq(), 'ACTGACTGACTG';
ok $a->display_id(),'new-id' ;
ok $a->desc, 'Sample Bio::Seq object';
ok $a->alphabet(), 'dna';

ok defined($trunc = $a->trunc(1,4));
ok $trunc->seq(), 'ACTG', "Expecting ACTG. Got ". $trunc->seq();

ok defined($rev = $a->revcom());
ok $rev->seq(), 'CAGTCAGTCAGT';

$a->is_reference(1);
ok $a->is_reference;

$a->repeat_unit('ACTG');
ok $a->repeat_unit, 'ACTG';

$a->repeat_count(3);
ok $a->repeat_count, 3;

