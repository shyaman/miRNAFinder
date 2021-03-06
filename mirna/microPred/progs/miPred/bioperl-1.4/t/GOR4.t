# This is -*-Perl-*- code
## Bioperl Test Harness Script for Modules
##
# $Id: GOR4.t,v 1.1 2003/07/23 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'
use strict;
use vars qw($NUMTESTS $DEBUG $ERROR $METAERROR);
$DEBUG = $ENV{'BIOPERLDEBUG'} || 0;
BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    $ERROR = 0;
    if( $@ ) {
	use lib 't';
    }
    use Test;

    $NUMTESTS = 11;
    plan tests => $NUMTESTS;

    eval {
	require IO::String; 
	require LWP::UserAgent;
	
    }; 
    if( $@ ) {
        warn("IO::String or LWP::UserAgent not installed. This means that the module is not usable. Skipping tests");
	$ERROR = 1;
    }
	#check this is available, set error flag if not.
	eval {
		require Bio::Seq::Meta::Array;
		};
	if ($@) {
		warn ("Bio::Seq::Meta::Array not installed - will skip tests using meta sequences");
		$METAERROR = 1;
		}
}

END {
    foreach ( $Test::ntest..$NUMTESTS) {
	skip('unable to run all of the tests depending on web access',1);
    }
}

exit 0 if $ERROR ==  1;

use Data::Dumper;

use Bio::Seq;
require Bio::Tools::Analysis::Protein::GOR4;

ok 1;

my $verbose = 0;
$verbose = 1 if $DEBUG;

ok my $tool = Bio::WebAgent->new(-verbose =>$verbose);

my $seq = Bio::Seq->new(-seq => 'MSADQRWRQDSQDSFGDSFDGDPPPPPPPPFGDSFGDGFSDRSRQDQRS',
                        -display_id => 'test2',
                       );
ok $tool = Bio::Tools::Analysis::Protein::GOR4->new( -seq=>$seq->primary_seq,
                                                   );
if( $DEBUG ) {
    ok $tool->run ();
    exit if $tool->status eq 'TERMINATED_BY_ERROR';
    ok my $raw = $tool->result('');
    ok my $parsed = $tool->result('parsed');
    ok ($parsed->[0]{'coil'}, '0.999');
    my @res = $tool->result('Bio::SeqFeatureI');
    if (scalar @res > 0) {
	ok 1;
    } else {
	skip('No network access - could not connect to GOR4 server', 1);
    }
    ok my $meta = $tool->result('meta');
    
    if (!$METAERROR) { #if Bio::Seq::Meta::Array available
	
	ok ( $meta->named_submeta_text('GOR4_coil',1,2), '0.999 0.999');
	ok ( $meta->seq, 'MSADQRWRQDSQDSFGDSFDGDPPPPPPPPFGDSFGDGFSDRSRQDQRS');
    }
} else {
    for ( $Test::ntest..$NUMTESTS) {
	skip("Skipping tests which require remote servers - set env variable BIOPERLDEBUG to test",1);
    }
}
