# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: LocationFactory.t,v 1.4 2002/12/28 03:26:33 lapp Exp $

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
    plan tests => 177;
}

use Bio::Factory::FTLocationFactory;
use Bio::Factory::LocationFactoryI;
use Bio::Location::Simple;
use Bio::Location::Split;
use Bio::Location::Fuzzy;

my $simple_impl = "Bio::Location::Simple";
my $fuzzy_impl = "Bio::Location::Fuzzy";
my $split_impl = "Bio::Location::Split";

# Holds strings and results. The latter is an array of expected class name,
# min/max start position and position type, min/max end position and position
# type, location type, the number of locations, and the strand.
#
# note: the following are directly taken from 
# http://www.ncbi.nlm.nih.gov/collab/FT/#location
my %testcases = ("467" => [$simple_impl,
		   467, 467, "EXACT", 467, 467, "EXACT", "EXACT", 1, 1],
		 "340..565" => [$simple_impl,
		   340, 340, "EXACT", 565, 565, "EXACT", "EXACT", 1, 1],
		 "<345..500" => [$fuzzy_impl,
		   undef, 345, "BEFORE", 500, 500, "EXACT", "EXACT", 1, 1],
		 "<1..888" => [$fuzzy_impl,
		   undef, 1, "BEFORE", 888, 888, "EXACT", "EXACT", 1, 1],
		 "(102.110)" => [$fuzzy_impl,
		   102, 102, "EXACT", 110, 110, "EXACT", "WITHIN", 1, 1],
		 "(23.45)..600" => [$fuzzy_impl,
		   23, 45, "WITHIN", 600, 600, "EXACT", "EXACT", 1, 1],
		 "(122.133)..(204.221)" => [$fuzzy_impl,
		   122, 133, "WITHIN", 204, 221, "WITHIN", "EXACT", 1, 1],
		 "123^124" => [$simple_impl,
		   123, 123, "EXACT", 124, 124, "EXACT", "IN-BETWEEN", 1, 1],
		 "145^177" => [$fuzzy_impl,
		   145, 145, "EXACT", 177, 177, "EXACT", "BETWEEN", 1, 1],
		 "join(12..78,134..202)" => [$split_impl,
		   12, 12, "EXACT", 202, 202, "EXACT", "EXACT", 2, 1],
		 "join(complement(4918..5163),complement(2691..4571))" => [$split_impl,
		   2691, 2691, "EXACT", 5163, 5163, "EXACT", "EXACT", 2, -1],
		 "complement(34..(122.126))" => [$fuzzy_impl,
		   34, 34, "EXACT", 122, 126, "WITHIN", "EXACT", 1, -1],
		 "J00194:100..202" => [$simple_impl,
		   100, 100, "EXACT", 202, 202, "EXACT", "EXACT", 1, 1],
		 # this variant is not really allowed by the FT definition
		 # document but we want to be able to cope with it
		 "J00194:(100..202)" => [$simple_impl,
		   100, 100, "EXACT", 202, 202, "EXACT", "EXACT", 1, 1],
		 "((122.133)..(204.221))" => [$fuzzy_impl,
		   122, 133, "WITHIN", 204, 221, "WITHIN", "EXACT", 1, 1],
		 "join(AY016290.1:108..185,AY016291.1:1546..1599)"=>
		 [$split_impl,
		  108, 108, "EXACT", 185, 185, "EXACT", "EXACT", 2, undef] 
		 );

my $locfac = Bio::Factory::FTLocationFactory->new();
ok($locfac->isa("Bio::Factory::LocationFactoryI"));

# sorting is to keep the order constant from one run to the next
foreach my $locstr (sort keys(%testcases)) { 
    my $loc = $locfac->from_string($locstr);
    if($locstr eq "join(AY016290.1:108..185,AY016291.1:1546..1599)") {
	$loc->seq_id("AY016295.1");
    }
    my @res = @{$testcases{$locstr}};
    ok(ref($loc), $res[0]);
    ok($loc->min_start(), $res[1]);
    ok($loc->max_start(), $res[2]);
    ok($loc->start_pos_type(), $res[3]);
    ok($loc->min_end(), $res[4]);
    ok($loc->max_end(), $res[5]);
    ok($loc->end_pos_type(), $res[6]);
    ok($loc->location_type(), $res[7]);
    my @locs = $loc->each_Location();
    ok(@locs, $res[8]);
    my $ftstr = $loc->to_FTstring();
    # this is a somewhat ugly hack, but we want clean output from to_FTstring()
    $locstr = "J00194:100..202" if $locstr eq "J00194:(100..202)";
    $locstr = "(122.133)..(204.221)" if $locstr eq "((122.133)..(204.221))";
    # now test
    ok($ftstr, $locstr);
    # test strand production
    ok($loc->strand(), $res[9]);
}
   
