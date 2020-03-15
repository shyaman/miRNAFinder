# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 05_load_them.t,v 1.1 2003/12/02 02:54:00 jettero Exp $

use strict;
use Test;

my @packages = map { s/\.pm$//; s/^.+?\///; "Statistics::Basic::$_" } <Basic/*.pm>;

plan tests => int @packages;

for my $p (@packages) {
    eval "use $p";

    if( $@ ) {
        warn " $@\n";
    } else {
        ok 1;
    }
}
