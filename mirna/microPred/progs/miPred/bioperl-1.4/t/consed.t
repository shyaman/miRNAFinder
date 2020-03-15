# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: consed.t,v 1.5 2002/10/30 14:21:59 heikki Exp $
#
#####
#
# this script simply tests parsing ace* files
# - it cares nothing about the chromat_dir,phd_dir,edit_dir types of things
#
#####

use strict;
use vars qw($TESTCOUNT);
BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
        use lib 't';
    }
    use Test;
    $TESTCOUNT = 16;
    plan tests => $TESTCOUNT;
}

use Bio::Root::IO;
use Bio::Tools::Alignment::Consed;
use vars qw($DEBUG);
$DEBUG = $ENV{'BIOPERLDEBUG'} || -1;

if( $^O =~ /mswin/i ) {
    for ( $Test::ntest..$TESTCOUNT ) {
	skip("Cannot run consed module on windows",1,1);	
    }
    exit(0);
}
print("Checking if the Bio::Tools::Alignment::Consed module could be used...\n") if $DEBUG > 0;
	# test 1
ok(1);

	# scope some variables
my($o_consed,@singlets,@singletons,@pairs,@doublets,@multiplets,$invoker);

# instantiate a new object
my $passed_in_acefile = Bio::Root::IO->catfile("t","data","acefile.ace.1");
$o_consed = Bio::Tools::Alignment::Consed->new(-acefile => $passed_in_acefile);
print("Checking if a new CSM::Consed object was created...\n") if( $DEBUG > 0);
ok defined $o_consed;

	# set the verbosity to a valid value (1)
ok my $verbosity = $o_consed->verbose(1);

# set the verbosity to "none"
$o_consed->verbose(0);
#
print("Checking if the new object is a reference to a Bio::Tools::Alignment::Consed object...\n") if($DEBUG > 0);
# test 3
ok( ref($o_consed),'Bio::Tools::Alignment::Consed');

print("Checking if singlets can be successfully set...\n"), if( $DEBUG > 0);
# test 4
ok ($o_consed->set_singlets() != 1);

print("Checking if the number of singlets can be retrieved and if that number is correct (65)...\n") if($DEBUG > 0);	
@singlets = $o_consed->get_singlets();
ok (scalar(@singlets), 65);

print("Checking if the doublets can be set...\n"), if( $DEBUG> 0);
ok ($o_consed->set_doublets() != 1);

print("Checking if the doublets can be retreived...\n") if($DEBUG > 0);
ok @doublets = $o_consed->get_doublets();

print(scalar(@doublets)." doublets were found\n") if ($DEBUG > 0);
print("Checking if the number of doublets can be retrieved and if that number is correct (45)...\n") if($DEBUG > 0);
ok (scalar(@doublets), 45);

print("Checking if the number of pairs can be retrieved and if that number is correct (1)...\n") if($DEBUG > 0);
@pairs = $o_consed->get_pairs();
ok (scalar(@pairs),1);

print("Checking if the number of multiplets can be retrieved and if that number is correct (4)...\n") if($DEBUG > 0);
@multiplets = $o_consed->get_multiplets();
ok (scalar(@multiplets), 4);

print("Checking if the number of singletons can be retrieved and if that number is correct (3)...\n") if($DEBUG > 0);
@singletons = $o_consed->get_singletons();
ok (scalar(@singletons), 3);
my($total_object_sequences, $total_grep_sequences);
print("Finding out, via grep, how many sequences there are in the acefile _and_ in the singlets file...\n") if $DEBUG > 0; 
ok($total_grep_sequences = $o_consed->count_sequences_with_grep(), 179);

print("Getting the statistics from the Bio::Tools::Alignment::Consed object to compare the total number of sequences accounted for there to the number of sequences found via grep...\n") if($DEBUG > 0);
ok($total_object_sequences = $o_consed->sum_lets("total_only"),179);
print("Match?\n") if($DEBUG > 0) ;
ok ($total_object_sequences, $total_grep_sequences);

print("These are the statistics. Look right? ".$o_consed->sum_lets()."\n") if($DEBUG > 0);
ok($o_consed->sum_lets(),'Singt/singn/doub/pair/mult/total : 65,3,45(90),1(2),4(19),179');

print("Dumping out the hash in a compact way...\n")if($DEBUG > 0)  ;
$o_consed->dump_hash_compact() if($DEBUG > 0)  ;

# print("Dumping out the hash in an ugly way...\n");
# $o_consed->dump_hash();

sub allele_script {
	my($a,$trunc,$rev);
	ok defined $a,
	ok ref($a), 'Bio::Variation::Allele';
	
	ok $a->accession_number(), 'X677667';
	ok $a->seq(), 'ACTGACTGACTG';
	ok $a->display_id(),'new-id' ;
	ok $a->desc, 'Sample Bio::Seq object';
	ok $a->moltype(), 'dna';

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
}
