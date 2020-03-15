# -*-Perl-*- mode for emacs
# $Id: PopGen.t,v 1.18 2003/11/11 02:37:40 jason Exp $

# This will outline many tests for the population genetics
# objects in the Bio::PopGen namespace

my $error;

use vars qw($SKIPXML $LASTXMLTEST); 
use strict;
use lib '.';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
	use lib 't';
    }
    use vars qw($NTESTS);
    $NTESTS = 74;
    $error = 0;

    use Test;
    plan tests => $NTESTS; 

}

if( $error == 1 ) {
    exit(0);
}


use Bio::PopGen::Individual;
use Bio::PopGen::Genotype;
use Bio::PopGen::Population;
use Bio::PopGen::IO;
use Bio::PopGen::PopStats;

use Bio::PopGen::Statistics;

my ($FILE1) = qw(popgentst1.out);

END { 
    # unlink($FILE1);
}
my @individuals = ( new Bio::PopGen::Individual(-unique_id => '10a'));
ok($individuals[0]);

my @genotypes = ( new Bio::PopGen::Genotype(-marker_name    => 'Mkr1',
					    -individual_id  => '10a',
					    -alleles => [ qw(A a)]),
		  new Bio::PopGen::Genotype(-marker_name    => 'Mkr2',
					    -individual_id  => '10a',
					    -alleles => [ qw(B B)]),
		  new Bio::PopGen::Genotype(-marker_name    => 'Mkr3',
					    -individual_id  => '10a',
					    -alleles => [ qw(A a)]));
ok(($genotypes[1]->get_Alleles)[0], 'B');

$individuals[0]->add_Genotype(@genotypes);
ok($individuals[0]->get_Genotypes,3);
ok($individuals[0]->get_Genotypes(-marker => 'Mkr3')->get_Alleles(),2);
my @alleles = $individuals[0]->get_Genotypes(-marker => 'Mkr2')->get_Alleles();
ok($alleles[0], 'B');

					     
my $population = new Bio::PopGen::Population(-name        => 'TestPop1',
					     -source      => 'testjasondata',
					     -description => 'throw away example',
					     -individuals => \@individuals);

ok(scalar ($population->get_Individuals()), 1);
ok($population->name, 'TestPop1');
ok($population->source, 'testjasondata');
ok($population->description, 'throw away example');

my @genotypes2 = ( new Bio::PopGen::Genotype(-marker_name   => 'Mkr1',
					     -individual_id => '11',
					     -alleles       => [ qw(A A)]),
		   new Bio::PopGen::Genotype(-marker_name   => 'Mkr2',
					     -individual_id => '11',
					     -alleles       => [ qw(B B)]),
		   new Bio::PopGen::Genotype(-marker_name   => 'Mkr3',
					     -individual_id => '11',
					     -alleles       => [ qw(a a)]),
		   new Bio::PopGen::Genotype(-marker_name   => 'Mkr4',
					     -individual_id => '11',
					     -alleles       => [ qw(C C)])
		   );
push @individuals, new Bio::PopGen::Individual(-genotypes   => \@genotypes2,
					       -unique_id   => '11');
$population->add_Individual($individuals[1]);

ok(scalar ($population->get_Individuals()), 2);
my ($found_ind) = $population->get_Individuals(-unique_id => '10a');
ok($found_ind->unique_id, '10a');
ok(scalar($population->get_Individuals(-marker => 'Mkr4')) , 1);
ok(scalar($population->get_Individuals(-marker => 'Mkr3')) , 2);

my @g = $population->get_Genotypes(-marker => 'Mkr4');

ok($g[0]->individual_id, '11');
ok(($g[0]->get_Alleles())[0], 'C');

my $marker = $population->get_Marker('Mkr3');
ok($marker);

@alleles = $marker->get_Alleles;
ok(@alleles,2);
my %af = $marker->get_Allele_Frequencies();
ok($af{'a'}, 0.75);
ok($af{'A'}, 0.25);


# Read in data from a file
my $io = new Bio::PopGen::IO(-format => 'csv',
			     -file   => Bio::Root::IO->catfile(qw(t data
								  popgen_saureus.dat)));

my @inds;
while( my $ind = $io->next_individual ) {
    push @inds, $ind;
}

my @mrsainds = grep { $_->unique_id =~ /^MRSA/ } @inds;
my @mssainds = grep { $_->unique_id =~ /^MSSA/ } @inds;
my @envinds = grep { $_->unique_id =~ /^NC/ } @inds;

ok(scalar @mrsainds, 9);
ok(scalar @mssainds, 10);
ok(scalar @envinds, 5);

my $mrsapop = new Bio::PopGen::Population(-name        => 'MRSA',
					  -description => 'Resistant S.aureus',
					  -individuals => \@mrsainds);

my $mssapop = new Bio::PopGen::Population(-name        => 'MSSA',
					  -description =>'Suceptible S.aureus',
					  -individuals => \@mssainds);

my $envpop = new Bio::PopGen::Population(-name        => 'NC',
					 -description => 'WT isolates',
					  -individuals => \@envinds);

my $stats = new Bio::PopGen::PopStats(-haploid => 1);
my $fst = $stats->Fst([$mrsapop,$mssapop],[qw(AFLP1 )]);
# We're going to check the values against other programs first
ok(sprintf("%.3f",$fst),0.077,'mrsa,mssa aflp1'); 
  
$fst = $stats->Fst([$envpop,$mssapop,$mrsapop],[qw(AFLP1 )]);
ok(sprintf("%.3f",$fst),0.035,'all pops, aflp1'); 

$fst = $stats->Fst([$mrsapop,$envpop],[qw(AFLP1 AFLP2)]);
ok(sprintf("%.3f",$fst),0.046,'mrsa,envpop aflp1,aflp2');

# Read in data from a file
$io = new Bio::PopGen::IO(-format => 'csv',
			  -file   => Bio::Root::IO->catfile
			  (qw(t data popgen_saureus.multidat)));

@inds = ();
while( my $ind = $io->next_individual ) {
    push @inds, $ind;
}

@mrsainds = grep { $_->unique_id =~ /^MRSA/ } @inds;
@mssainds = grep { $_->unique_id =~ /^MSSA/ } @inds;
@envinds = grep { $_->unique_id =~ /^NC/ } @inds;

ok(scalar @mrsainds, 7);
ok(scalar @mssainds, 10);
ok(scalar @envinds, 5);

$mrsapop = new Bio::PopGen::Population(-name        => 'MRSA',
				       -description => 'Resistant S.aureus',
				       -individuals => \@mrsainds);

$mssapop = new Bio::PopGen::Population(-name        => 'MSSA',
				       -description =>'Suceptible S.aureus',
				       -individuals => \@mssainds);

$envpop = new Bio::PopGen::Population(-name        => 'NC',
				      -description => 'WT isolates',
				      -individuals => \@envinds);

$stats = new Bio::PopGen::PopStats(-haploid => 1);
my @all_bands = map { 'B' . $_ } 1..20;
my @mkr1     = map { 'B' . $_ } 1..13;
my @mkr2     = map { 'B' . $_ } 14..20;

# still wrong ?
$fst = $stats->Fst([$mrsapop,$mssapop],[@all_bands ]);
skip(sprintf("%.3f",$fst),'-0.001','mssa,mrsa all_bands'); # We're going to check the values against other programs first
$fst = $stats->Fst([$envpop,$mssapop],[ @mkr1 ]);
ok(sprintf("%.3f",$fst),0.023,'env,mssa mkr1'); # We're going to check the values against other programs first

$fst = $stats->Fst([$envpop,$mssapop,$mrsapop],[ @all_bands ]);
ok(sprintf("%.3f",$fst),0.071,'env,mssa,mrsa all bands'); # We're going to check the values against other programs first

$fst = $stats->Fst([$envpop,$mssapop,$mrsapop],[ @mkr2 ]);
ok(sprintf("%.3f",$fst),0.076, 'env,mssa,mrsa mkr2'); # We're going to check the values against other programs first

$fst = $stats->Fst([$mrsapop,$envpop],[@all_bands ]);
ok(sprintf("%.3f",$fst),0.241,'mrsa,nc all_bands'); # We're going to check the values against other programs first

# test overall allele freq setting for a population

my $poptst1 = new Bio::PopGen::Population(-name => 'tst1');
my $poptst2 = new Bio::PopGen::Population(-name => 'tst2');

$poptst1->set_Allele_Frequency(-frequencies => 
			       { 'marker1' => { 'a' => '0.20',
						'A' => '0.80' },
				 'marker2' => { 'A' => '0.10',
						'B' => '0.20',
						'C' => '0.70' }
			     });

my $mk1 = $poptst1->get_Marker('marker1');
my %f1 = $mk1->get_Allele_Frequencies;
ok($f1{'a'}, '0.20');
ok($f1{'A'}, '0.80');
my $mk2 = $poptst1->get_Marker('marker2');
my %f2 = $mk2->get_Allele_Frequencies;
ok($f2{'C'}, '0.70');

$poptst2->set_Allele_Frequency(-name      => 'marker1',
			       -allele    => 'A',
			       -frequency => '0.60');
$poptst2->set_Allele_Frequency(-name      => 'marker1',
			       -allele    => 'a',
			       -frequency => '0.40');

#$fst = $stats->Fst([$poptst1,$poptst2],[qw(marker1 marker2) ]);
skip('Fst not calculated yet',1,'marker1 test'); # 


$io = new Bio::PopGen::IO(-format => 'csv',
			  -file   => ">$FILE1");

$io->write_individual(@inds);
$io->close();
ok( -e $FILE1);
unlink($FILE1);
$io = new Bio::PopGen::IO(-format => 'csv',
			  -file   => ">$FILE1");

$io->write_population(($mssapop,$mrsapop));
$io->close();
ok( -e $FILE1);
unlink($FILE1);

$io = new Bio::PopGen::IO(-format => 'prettybase',
			  -file   => ">$FILE1");

$io->write_individual(@inds);
$io->close();
ok( -e $FILE1);
unlink($FILE1);

$io = new Bio::PopGen::IO(-format => 'prettybase',
			  -file   => ">$FILE1");

$io->write_population(($mssapop,$mrsapop));
$io->close();
ok( -e $FILE1);
unlink($FILE1);


# Let's do PopGen::Statistics tests here

$io = new Bio::PopGen::IO(-format          => 'prettybase',
			  -no_header       => 1,
			  -file            => Bio::Root::IO->catfile
			  (qw(t data popstats.prettybase)));
my (@ingroup,@outgroup);
my $sitecount;
while( my $ind = $io->next_individual ) {
    if($ind->unique_id =~ /out/) {
	push @outgroup, $ind;
    } else { 
	push @ingroup, $ind;
	$sitecount = scalar $ind->get_marker_names() unless defined $sitecount;
    }
}
$stats = new Bio::PopGen::Statistics();

# Real data and values courtesy M.Hahn and DNASP

ok($stats->pi(\@ingroup),2);
ok(Bio::PopGen::Statistics->pi(\@ingroup,$sitecount),0.4);

ok(Bio::PopGen::Statistics->theta(\@ingroup),1.92);
ok(Bio::PopGen::Statistics->theta(\@ingroup,$sitecount),0.384);

# Test with a population object
my $ingroup  = new Bio::PopGen::Population(-individuals => \@ingroup);
my $outgroup = new Bio::PopGen::Population(-individuals => \@outgroup);

ok($stats->pi($ingroup),2);
ok(Bio::PopGen::Statistics->pi($ingroup,$sitecount),0.4);

ok(Bio::PopGen::Statistics->theta($ingroup),1.92);
ok(Bio::PopGen::Statistics->theta($ingroup,$sitecount),0.384);

# to fix
ok(sprintf("%.5f",Bio::PopGen::Statistics->tajima_D(\@ingroup)),0.27345);
ok(sprintf("%.5f",Bio::PopGen::Statistics->tajima_D($ingroup)),0.27345);


ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D_star(\@ingroup)),
   0.27345);
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D_star($ingroup)),
   0.27345);

skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F_star(\@ingroup)),
   0.27834);
skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F_star($ingroup)),
   0.27834);

ok((Bio::PopGen::Statistics->derived_mutations(\@ingroup,\@outgroup))[0], 1);
ok((Bio::PopGen::Statistics->derived_mutations($ingroup,\@outgroup))[0], 1);
ok((Bio::PopGen::Statistics->derived_mutations(\@ingroup,$outgroup))[0], 1);
ok((Bio::PopGen::Statistics->derived_mutations($ingroup,$outgroup))[0], 1);

# expect to have 1 external mutation
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D(\@ingroup,1)),0.75653);
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D($ingroup,1)),0.75653);

ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D(\@ingroup,
						       \@outgroup)),0.75653);
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D($ingroup,
						       \@outgroup)),0.75653);
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D($ingroup,
						       $outgroup)),0.75653);
ok(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_D(\@ingroup,
						       $outgroup)),0.75653);

skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F(\@ingroup,1)),0.77499);
skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F($ingroup,1)),0.77499);
skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F($ingroup,
						       \@outgroup)),0.77499);
skip(sprintf("%.5f",Bio::PopGen::Statistics->fu_and_li_F($ingroup,
						       $outgroup)),0.77499);


# Test composite LD

$io = new Bio::PopGen::IO(-format => 'prettybase',
			  -file   => Bio::Root::IO->catfile
			  (qw(t data compLD_test.prettybase)));

my $pop = $io->next_population;

my %LD = $stats->composite_LD($pop);

ok($LD{'01'}->{'02'}->[1], 10);
ok($LD{'01'}->{'03'}->[1], 0);
ok($LD{'02'}->{'03'}->[1], 0);

# Test composite LD

$io = new Bio::PopGen::IO(-format => 'prettybase',
			  -file   => Bio::Root::IO->catfile
			  (qw(t data compLD_missingtest.prettybase)));

$pop = $io->next_population;

%LD = $stats->composite_LD($pop);

ok(sprintf("%.4f",$LD{'ProC9198EA'}->{'ProcR2973EA'}->[0]), -0.0375);
ok(sprintf("%.2f",$LD{'ProC9198EA'}->{'ProcR2973EA'}->[1]), 2.56);
