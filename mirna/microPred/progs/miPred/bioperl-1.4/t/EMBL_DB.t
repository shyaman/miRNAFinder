# This is -*-Perl-*- code
## Bioperl Test Harness Script for Modules
##
# $Id: EMBL_DB.t,v 1.12 2002/12/02 15:38:31 jason Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG);
$DEBUG = $ENV{'BIOPERLDEBUG'} || 0;

my $error;

BEGIN { 
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    $error = 0;
    if( $@ ) {
	use lib 't';
    }
    use Test;

    $NUMTESTS = 15;
    plan tests => $NUMTESTS;
    eval { require 'IO/String.pm' };
    if( $@ ) {
	for( $Test::ntest..$NUMTESTS ) {
	    skip("IO::String not installed. This means the Bio::DB::* modules are not usable. Skipping tests",1);
	}
       $error = 1; 
    }
}
END { 
    foreach ( $Test::ntest..$NUMTESTS) {
	skip('unable to run all of the Biblio_biofetch tests',1);
    }
}

if( $error ==  1 ) {
    exit(0);
}

require Bio::DB::EMBL;

my $verbose = 0;

## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

my ($db,$seq,$seqio);
# get a single seq

$seq = $seqio = undef;

eval { 
    ok defined($db = new Bio::DB::EMBL(-verbose=>$verbose)); 
    ok(defined($seq = $db->get_Seq_by_acc('J00522')));
    ok( $seq->length, 408); 
    ok defined ($db->request_format('fasta'));
    ok(defined($seq = $db->get_Seq_by_acc('J02231')));
    ok( $seq->id, qr/embl.+BUM/);
    ok( $seq->length, 200); 
    ok( defined($db = new Bio::DB::EMBL(-verbose=>$verbose, 
					-retrievaltype => 'tempfile')));
    ok(defined($seqio = $db->get_Stream_by_id(['BUM'])));
    undef $db; # testing to see if we can remove gb
    ok( defined($seq = $seqio->next_seq()));
    ok( $seq->length, 200);
};

if ($@) {
    if( $DEBUG ) {
	warn "Warning: Couldn't connect to EMBL with Bio::DB::EMBL.pm!\n$@";
    }
    foreach ( $Test::ntest..$NUMTESTS) { 
	 skip('could not connect to embl',1);
     }
    exit(0);
}

$seq = $seqio = undef;

eval {
    $db = new Bio::DB::EMBL(-verbose => $verbose,
			    -retrievaltype => 'tempfile',
			    -format => 'fasta'
			    ); 
    ok( defined($seqio = $db->get_Stream_by_acc(['J00522 AF303112 J02231'])));
    ok($seqio->next_seq->length, 408);
    ok($seqio->next_seq->length, 1611);
    ok($seqio->next_seq->length, 200);
};

if ($@) {
    if( $DEBUG ) {
	warn "Batch access test failed.\nError: $@\n";
    }
    foreach ( $Test::ntest..$NUMTESTS ) { skip('no network access',1); }
}


