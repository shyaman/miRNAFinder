# -*-Perl-*- mode (to keep my emacs happy)
# $Id: Unflattener2.t,v 1.6 2003/12/12 20:39:16 cjm Exp $

use strict;
use vars qw($DEBUG $TESTCOUNT);
BEGIN {     
    eval { require Test; };
    if( $@ ) {
	use lib 't';
    }
    use Test;
    $TESTCOUNT = 11;
    plan tests => $TESTCOUNT;
}

use Bio::Seq;
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::SeqFeature::Tools::Unflattener;

ok(1);

my $verbosity = 0;   # Set to -1 for release version, so warnings aren't printed
#$verbosity = 1;

my ($seq, @sfs);
my $unflattener = Bio::SeqFeature::Tools::Unflattener->new;
$unflattener->verbose($verbosity);

if (1) {
    
    # this is an arabidopsise gbk record. it has no mRNA features.
    # it has explicit exon/intron records

    my @path = ("t","data","ATF14F8.gbk");
    $seq = getseq(@path);
    
    ok ($seq->accession_number, 'AL391144');
    my @topsfs = $seq->get_SeqFeatures;
    my @cdss = grep {$_->primary_tag eq 'CDS'} @topsfs;
    my $n = scalar(@topsfs);
    printf "TOP:%d\n", scalar(@topsfs);
#    write_hier(@topsfs);
    
    # UNFLATTEN
    @sfs = $unflattener->unflatten_seq(-seq=>$seq,
				       -use_magic=>1,
				      );
    print "\n\nPOST PROCESSING:\n";
    @sfs = $seq->get_SeqFeatures;
    write_hier(@sfs);
    printf "PROCESSED/TOP:%d\n", scalar(@sfs);
    ok(@sfs == 28);
    my @allsfs = $seq->get_all_SeqFeatures;
    printf "ALL:%d\n", scalar(@allsfs);
    ok(@allsfs == 202);
    my @mrnas = grep {$_->primary_tag eq 'mRNA'} @allsfs;
    printf "mRNAs:%d\n", scalar(@mrnas);
    # relationship between mRNA and CDS should be one-one
    ok(@mrnas == @cdss);
}

if (1) {
    
    # this is a record from FlyBase
    # it has mRNA features, and explicit exon/intron records

    my @path = ("t","data","AnnIX-v003.gbk");
    $seq = getseq(@path);
    
    my @topsfs = $seq->get_SeqFeatures;
    printf "TOP:%d\n", scalar(@topsfs);
#    write_hier(@topsfs);
    
    # UNFLATTEN
    @sfs = $unflattener->unflatten_seq(-seq=>$seq,
				       -use_magic=>1,
				      );
    print "\n\nPOST PROCESSING:\n";
    @sfs = $seq->get_SeqFeatures;
    write_hier(@sfs);
    printf "PROCESSED/TOP:%d\n", scalar(@sfs);
    ok(@sfs == 1);
    my @exons = grep {$_->primary_tag eq 'exon'} $seq->get_all_SeqFeatures;
    ok(@exons == 10);    # total number of exons per splice
    my %numberh = map {$_->get_tag_values("number") => 1} @exons;
    my @numbers = keys %numberh;
    printf "DISTINCT EXONS: %d [@numbers]\n", scalar(@numbers);
    ok(@numbers == 6);  # distinct exons
}

if (1) {
    
    # example of a BAD genbank entry

    my @path = ("t","data","dmel_2Lchunk.gb");
    $seq = getseq(@path);
    
    my @topsfs = $seq->get_SeqFeatures;
    printf "TOP:%d\n", scalar(@topsfs);
#    write_hier(@topsfs);
    
    # UNFLATTEN
    #
    # we EXPECT problems with this erroneous record
    $unflattener->error_threshold(2);
    @sfs = $unflattener->unflatten_seq(-seq=>$seq,
                                       -use_magic=>1,
                                      );
    my @probs = $unflattener->get_problems;
    $unflattener->report_problems(\*STDOUT);
    $unflattener->clear_problems;
    print "\n\nPOST PROCESSING:\n";
    @sfs = $seq->get_SeqFeatures;
    write_hier(@sfs);
    printf "PROCESSED/TOP:%d\n", scalar(@sfs);
    ok(@sfs == 2);
    my @exons = grep {$_->primary_tag eq 'exon'} $seq->get_all_SeqFeatures;
    ok(@exons == 6);    # total number of exons per splice

    printf "PROBLEMS ENCOUNTERED: %d (EXPECTED: 6)\n", scalar(@probs);
    ok(@probs == 6);
}


sub write_hier {
    my @sfs = @_;
    _write_hier(0, @sfs);
}
sub _write_hier {
    my $indent = shift;
    my @sfs = @_;
    foreach my $sf (@sfs) {
        my $label = '?';
        if ($sf->has_tag('gene')) {
            ($label) = $sf->get_tag_values('gene');
        }
        if ($sf->has_tag('product')) {
            ($label) = $sf->get_tag_values('product');
        }
        if ($sf->has_tag('number')) {
            $label = join("; ", $sf->get_tag_values('number'));
        }
        printf "%s%s $label\n", '  ' x $indent, $sf->primary_tag;
        my @sub_sfs = $sf->sub_SeqFeature;
        _write_hier($indent+1, @sub_sfs);
    }
}

sub getseq {
    my @path = @_;
    my $seqio =
      Bio::SeqIO->new('-file'=> Bio::Root::IO->catfile(
                                                       @path
                                                      ), 
                      '-format' => 'GenBank');
    $seqio->verbose($verbosity);

    my $seq = $seqio->next_seq();
    return $seq;
}

# 1 2,3
# 2 1,2
# 3 4,5
# 4 1,4,5,6
# 5 1,4,5,6
# 6 1,4,5,6
