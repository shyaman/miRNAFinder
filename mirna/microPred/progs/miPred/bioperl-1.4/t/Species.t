# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: Species.t,v 1.6 2001/01/25 22:13:40 jason Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
# Test script for Bio::Species.pm
# Hilmar Lapp <Hilmar.Lapp@pharma.novartis.com>, <hlapp@gmx.net>
# Fairly rudimentary
# Header code for this test was borrowed from Blast.t

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

    plan tests => 9;
}

use Bio::Species;

ok(1);

my $sps = Bio::Species->new();
ok defined $sps;
my $msg = 'bug in either Species->classification() or elsewhere in Bio::Species';
$sps->classification('sapiens', 'Homo', 'Hominidae',
		     'Catarrhini', 'Primates', 'Eutheria', 'Mammalia',
		     'Vertebrata', 'Chordata', 'Metazoa', 'Eukaryota');
ok $sps->binomial(), 'Homo sapiens', $msg;

$sps->classification('sapiens', 'Homo', 'Hominidae',
		     'Catarrhini', 'Primates', 'Eutheria', 'Mammalia',
		     'Vertebrata', 'Chordata', 'Metazoa', 'Eukaryota');
$sps->sub_species('sapiensis');
ok $sps->binomial(), 'Homo sapiens', $msg;
ok $sps->binomial('FULL'), 'Homo sapiens sapiensis', $msg;
ok $sps->sub_species(), 'sapiensis', $msg;

$sps->classification(qw( sapiens Homo Hominidae
			 Catarrhini Primates Eutheria Mammalia Vertebrata
			 Chordata Metazoa Eukaryota));
ok $sps->binomial(), 'Homo sapiens', $msg;

# test cmd line initializtion
my $species = new Bio::Species( -classification => 
				[ qw( sapiens Homo Hominidae
				      Catarrhini Primates Eutheria 
				      Mammalia Vertebrata
				      Chordata Metazoa Eukaryota) ] );
ok( $species);
ok $species->binomial(), 'Homo sapiens';
