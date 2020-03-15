# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: BlastIndex.t,v 1.6 2003/05/19 16:27:06 jason Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS);
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
    $NUMTESTS = 13;
    plan tests => $NUMTESTS;
    eval { require 'IO/String.pm' };
    if( $@ ) {
        for( $Test::ntest..$NUMTESTS ) {
            skip("IO::String not installed. This means the Bio::Index::Blast modules are not usable. Skipping tests",1);
        }
       $error = 1;
    }
}
if( $error ==  1 ) {
    exit(0);
}

require Bio::SearchIO;
require Bio::Index::Blast;
require Bio::Root::IO;

use Cwd;
END {  unlink qw( Wibbl Wibbl.pag Wibbl.dir ); }

ok(1);

my $index = new Bio::Index::Blast(-filename => 'Wibbl',
				  -write_flag => 1);
ok($index);

$index->make_index(Bio::Root::IO->catfile(cwd,"t","data","multi_blast.bls"));
($index->dbm_package eq 'SDBM_File') ? 
    (ok(-e "Wibbl.pag" && -e "Wibbl.dir")) :
    (ok(-e "Wibbl"));

foreach my $id ( qw(CATH_RAT PAPA_CARPA) ) {
    my $fh = $index->get_stream($id);
    ok($fh);
    ok( ! eof($fh) );
    my $report = new Bio::SearchIO(-noclose => 1,
				   -format  => 'blast',
				   -fh      => $fh);
    my $result = $report->next_result;
    ok($result->query_name, qr/$id/);
    ok( $result->next_hit);
    
    ok( $index->fetch_report($id)->query_name, qr/$id/);
}

