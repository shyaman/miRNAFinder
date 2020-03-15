# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 07_vector.t,v 1.3 2003/12/09 01:58:09 jettero Exp $

use strict;
use Test;
use Statistics::Basic::Vector;

plan tests => 7;

my $normalize    = undef;
my $no_normalize = 1;

my  $v = new Statistics::Basic::Vector([1..3]);

ok( $v->size == 3 );

    $v->set_size( 4, $normalize ); # fix_size() fills in with 0s
ok( $v->size == 4 ); 

    $v->set_size( 5, $no_normalize ); # waits for you to insert()
ok( $v->size == 4 );

    $v->insert( 5);  # this runs the normalizer whether you like it or not
ok( $v->size == 5 ); # and of course, by normalizer, we mean 0-padder

    $v->insert( [10..13], 14..15 );
ok( $v->size == 5 );

my  $j = new Statistics::Basic::Vector;
ok( not defined $j->size );
    $j->set_vector([7,9,21]);
ok( $j->size == 3 );
