# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: RangeI.t,v 1.5 2001/09/19 16:43:10 heikki Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw(@funcs);
BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
	use lib 't';
    }
    use Test;
    @funcs = qw(start end length strand overlaps contains 
		equals intersection union overlap_extent);
    plan tests => 19;
}

use Bio::RangeI;

my $i = 1;
my $func;
while ($func = shift @funcs) {
    $i++;
  if(exists $Bio::RangeI::{$func}) {
    ok(1);
    next if $func eq 'union';
    eval {
      $Bio::RangeI::{$func}->();
    };
    ok( $@ );
  } else {
    ok(0);
  }
}
