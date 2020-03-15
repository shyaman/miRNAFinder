# This is -*-Perl-*- code
## Bioperl Test Harness Script for Modules
##
# $Id: BioFetch_DB.t,v 1.9 2003/10/25 14:52:22 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG);
$DEBUG = $ENV{'BIOPERLDEBUG'} || 0;

use lib '.','./blib/lib';

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

    $NUMTESTS = 27;
    plan tests => $NUMTESTS;

    unless( eval "require IO::String; 1;" ) {
#      warn $@;
      for( $Test::ntest..$NUMTESTS ) {
	skip("IO::String not installed. This means that Bio::DB::BioFetch module is not usable. Skipping tests.",1);
      }
      $error = 1;
    }
}

END { 
    foreach ( $Test::ntest..$NUMTESTS) {
	skip('unable to run all of the Biblio/Biofetch tests - probably no network',1);
    }
}

if( $error ==  1 ) {
    exit(0);
}


require Bio::DB::BioFetch;

my $verbose = -1;

## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

my ($db,$db2,$seq,$seqio);
# get a single seq

$seq = $seqio = undef;

ok defined($db = new Bio::DB::BioFetch(-verbose => $verbose));
eval {
    # get a RefSeq entry
    ok $db->db('refseq');
    $seq = $db->get_Seq_by_acc('NM_006732'); # RefSeq VERSION
    $seq ? ok 1 : exit;
    ok $seq->accession_number;

    # EMBL
    $db->db('embl');
    ok(defined($seq = $db->get_Seq_by_acc('J00522')));
    ok( $seq->length, 408);
    ok(defined($seq = $db->get_Seq_by_acc('J02231')));
    ok $seq->id, 'BUM';
    ok( $seq->length, 200); 
    ok(defined($seqio = $db->get_Stream_by_id(['BUM'])));
    undef $db; # testing to see if we can remove gb
    ok( defined($seq = $seqio->next_seq()));
    ok( $seq->length, 200);

    #swissprot
    ok defined($db2 = new Bio::DB::BioFetch( -db => 'swall'));
    ok(defined($seq = $db2->get_Seq_by_id('YNB3_YEAST')));
    ok( $seq->length, 125);
    ok($seq->division, 'YEAST');
    $db2->request_format('fasta');
    ok(defined($seq = $db2->get_Seq_by_acc('P43780')));
    ok($seq->length,103); 

};

if ($@) {
    if( $DEBUG ) {
	print STDERR "Warning: Couldn't connect to EMBL with Bio::DB::EMBL.pm!\n" . $@;
    }
    foreach ( $Test::ntest..$NUMTESTS) { 
	skip('No network access - could not connect to embl',1);
    }
    exit(0);
}


$seq = $seqio = undef;

eval {
    $db = new Bio::DB::BioFetch(-retrievaltype => 'tempfile',
				 -format => 'fasta',
				 -verbose => $verbose
				);
    ok( defined($seqio = $db->get_Stream_by_id('J00522 AF303112 J02231')));
    ok($seqio->next_seq->length, 408);
    ok($seqio->next_seq->length, 1611);
    ok($seqio->next_seq->length, 200);
};

if ($@) {
    if( $DEBUG ) { warn "Batch access test failed.\nError: $@\n"; }
    foreach ( $Test::ntest..$NUMTESTS ) { skip('no network access skipping fasta retrieval',1); }
    exit(0);
}

$verbose = -1;
ok $db = new Bio::DB::BioFetch(-db => 'EMBL',
			       -verbose => $verbose);
eval {
    $seq = $db->get_Seq_by_acc('NT_006732');
};
ok $@;

eval {
    ok $seq = $db->get_Seq_by_acc('NM_006732');
    ok($seq );
    ok($seq->length, 3775);
};

if ($@) {
    if( $DEBUG ) { 
	print STDERR "Warning: Couldn't connect to BioFetch server with Bio::DB::BioFetch.pm!\n" . $@;
    }
    foreach ( $Test::ntest..$NUMTESTS) { 
	skip('No network aceess - could not connect to embl',1);
    }
    exit(0);
}
