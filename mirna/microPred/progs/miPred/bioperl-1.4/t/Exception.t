# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: Exception.t,v 1.5 2003/03/07 21:11:09 sac Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

my $error;

use strict;
use lib '.';
use lib './examples/root/lib';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
	use lib 't';
    }
    use vars qw($NTESTS);
    $NTESTS = 8;
    $error = 0;

    use Test;
    plan tests => $NTESTS; 
}

if( $error == 1 ) {
    exit(0);
}

use Bio::Root::Exception;
use TestObject;
use Error qw(:try);

ok(1);

$Error::Debug = 1; 

# Set up a tester object.
my $test = TestObject->new();

ok($test);

ok($test->data('Eeny meeny miney moe.'), 'Eeny meeny miney moe.');

# This demonstrates what will happen if a method defined in an interface 
# that is not implemented in the implementating object.
try {
    $test->foo();
}
catch Bio::Root::NotImplemented with {
    my $err = shift;
    ok(ref $err, 'Bio::Root::NotImplemented');
};

# TestObject::bar() deliberately throws a Bio::TestException, 
# which is defined in TestObject.pm
try {
    $test->bar;
}
catch Bio::TestException with {
    my $err = shift;
    ok(ref $err, 'Bio::TestException');
};


# Use the non-object-oriented syntax to throw a generic Bio::Root::Exception.
try {
    throw Bio::Root::Exception( "A generic error", 42 );
}
catch Bio::Root::Exception with {
    my $err = shift;
    ok(ref $err, 'Bio::Root::Exception');
    ok($err->value, 42);
};

# Try to call a subroutine that doesn't exist. But because it occurs within a try block,
# the Error module will create a Error::Simple to capture it. Handy eh?
if( defined $^V && $^V ge 5.6.1 ) {
    try {
	$test->foobar();
    }
    otherwise {
	my $err = shift;
	ok(ref $err, 'Error::Simple');
    }; 
} else { 
    skip("Can't run this test on perl < 5.6.1",1);
}

