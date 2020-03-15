# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: Chain.t,v 1.7 2001/01/25 22:13:40 jason Exp $
# Created: Wed Dec 13 15:52:33 GMT 2000
# By Joseph A.L. Insana, <insana@ebi.ac.uk>
#
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
    plan tests => 45;
}

use Bio::LiveSeq::Chain;

ok(1);

## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

my $chain = Bio::LiveSeq::Chain::string2chain("abcdefghijklmnopqrstuvwxyz");
ok defined $chain;
ok( Bio::LiveSeq::Chain::down_chain2string($chain), 
    "abcdefghijklmnopqrstuvwxyz");
ok( Bio::LiveSeq::Chain::down_chain2string($chain,undef,4),
    "abcd"); # default start=1
my ($warning,$output);
eval {
  local $SIG{__WARN__}=sub{ $warning=$_[0]};
  $output=Bio::LiveSeq::Chain::down_chain2string($chain,1,4,6);
};
ok (((index($warning,"Warning chain2string: argument LAST:6 overriding LEN:4!")==0)&&($output eq "abcdef")),1);
my $arrayref=Bio::LiveSeq::Chain::down_labels($chain,1,4);
ok $arrayref->[1], 2;
$arrayref=Bio::LiveSeq::Chain::up_labels($chain,4,1);
ok $arrayref->[1], 3;
$arrayref=Bio::LiveSeq::Chain::up_labels($chain);
ok scalar(@{$arrayref}), 26; # total number of labels should be 26
ok Bio::LiveSeq::Chain::start($chain), '1';
ok Bio::LiveSeq::Chain::end($chain), '26';
ok Bio::LiveSeq::Chain::label_exists($chain,'4');
ok Bio::LiveSeq::Chain::label_exists($chain,'28'), '0';
ok Bio::LiveSeq::Chain::down_get_pos_of_label($chain,4), '4';
ok Bio::LiveSeq::Chain::down_get_pos_of_label($chain,4,4), '1';
ok Bio::LiveSeq::Chain::up_get_pos_of_label($chain,26,1), '1';
ok Bio::LiveSeq::Chain::down_subchain_length($chain,1,4), '4';
ok Bio::LiveSeq::Chain::up_subchain_length($chain,4,1), '4';
ok Bio::LiveSeq::Chain::invert_chain($chain);
ok Bio::LiveSeq::Chain::invert_chain($chain);
ok Bio::LiveSeq::Chain::down_get_value_at_pos($chain,4), 'd';
ok Bio::LiveSeq::Chain::down_get_value_at_pos($chain,1,4), 'd';
ok Bio::LiveSeq::Chain::up_get_value_at_pos($chain,4), 'w';

ok Bio::LiveSeq::Chain::up_set_value_at_pos($chain,'W',4);
ok Bio::LiveSeq::Chain::up_get_value_at_pos($chain,4), 'W';

ok Bio::LiveSeq::Chain::down_set_value_at_pos($chain,'D',4); 
ok Bio::LiveSeq::Chain::down_get_value_at_pos($chain,4), 'D';

ok Bio::LiveSeq::Chain::set_value_at_label($chain,'d',4);
ok Bio::LiveSeq::Chain::get_value_at_label($chain,4), 'd';

ok Bio::LiveSeq::Chain::down_get_label_at_pos($chain,1,4), '4';
ok Bio::LiveSeq::Chain::up_get_label_at_pos($chain,4), '23';
ok Bio::LiveSeq::Chain::is_downstream($chain,3,4);
ok Bio::LiveSeq::Chain::is_downstream($chain,4,3), '0';
ok Bio::LiveSeq::Chain::is_upstream($chain,4,3);
ok Bio::LiveSeq::Chain::is_upstream($chain,3,4), '0';
ok Bio::LiveSeq::Chain::splice_chain($chain,4,2), 'de';
ok Bio::LiveSeq::Chain::splice_chain($chain,7,undef,9), 'ghi';

my @array=Bio::LiveSeq::Chain::praeinsert_string($chain,"ghi",10);
ok $array[0],27;
ok $array[1],29;

@array=Bio::LiveSeq::Chain::postinsert_string($chain,"de",3);
ok $array[0], 30;
ok $array[1], 31;
ok Bio::LiveSeq::Chain::up_chain2string($chain), "zyxWvutsrqponmlkjihgfedcba";

@array=Bio::LiveSeq::Chain::check_chain($chain);
ok $array[0], 1;
ok $array[1], 1;
ok $array[2], 1;
ok $array[3], 1;

