# -*-Perl-*-
## Bioperl Test Harness Script for Modules
##$Id: OddCodes.t,v 1.5 2001/10/22 08:22:58 heikki Exp $

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
    plan tests => 10;
}

use Bio::PrimarySeq;
use Bio::Tools::OddCodes;
ok 1;

my ($seqobj, $oddcode_obj);

$seqobj = Bio::PrimarySeq->new('-seq'=>'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
			       '-alphabet'=>'protein', 
			       '-id'=>'test');
$oddcode_obj  =  Bio::Tools::OddCodes->new('-seq' => $seqobj);

ok defined($oddcode_obj) && ref($oddcode_obj) && 
    $oddcode_obj->isa('Bio::Tools::OddCodes');

ok ${$oddcode_obj->structural()}, 'ABAEEIAEIJEIIEOAEEAAUIAXAZ';
ok ${$oddcode_obj->chemical()}, 'LBSAARLCLJCLSMOIMCHHULRXRZ';
ok ${$oddcode_obj->functional()}, 'HBPAAHPCHJCHHPOHPCPPUHHXPZ';
ok ${$oddcode_obj->charge()}, 'NBNAANNCNJCNNNONNCNNUNNXNZ';
ok ${$oddcode_obj->hydrophobic()}, 'IBOOOIOOIJOIIOOIOOOOUIIXOZ';
ok ${$oddcode_obj->Dayhoff()}, 'CBADDGCEFJEFFDOCDECCUFGXGZ';
ok ${$oddcode_obj->Sneath()}, 'CBEFFHCHAJGADDOCDGEEUAHXHZ';
ok ${$oddcode_obj->Stanfel()}, 'ABACCDAEAJEAACOACEAAUADXDZ';
