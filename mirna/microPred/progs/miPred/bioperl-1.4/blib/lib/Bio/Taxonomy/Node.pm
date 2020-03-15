# $Id: Node.pm,v 1.5 2003/10/25 15:00:58 heikki Exp $
#
# BioPerl module for Bio::Taxonomy::Node
#
# Cared for by Jason Stajich <jason-at-bioperl-dot-org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Taxonomy::Node - A node in a represented taxonomy

=head1 SYNOPSIS

  use Bio::Taxonomy::Node;
  # typically you will get a Node from a Bio::DB::Taxonomy object
  # but here is how you initialize one
  my $node = new Bio::Taxonomy::Node(-name      => $name,
                                     -object_id => $oid,
                                     -parent_id => $pid,
                                     -rank   => $rank,
                                     -division  => $div,
                                     -dbh       => $dbh);

  my $dbh = new Bio::DB::Taxonomy(-source   => 'flatfile',
                                  -directory=> '/tmp',
                                  -nodesfile=> '/path/to/nodes.dmp',
                                  -namesfile=> '/path/to/names.dmp');
  my $hum_node = $dbh->get_Taxonomy_Node(-name => 'Homo sapiens');
  my $hum_node2= $dbh->get_Taxonomy_Node(-taxonid => '9606');

  print "rank is ", $hum_node->rank, "\n";
  print "classification is ", join(" ", $hum_node->classification),"\n"; 
  print "division is ", $node->division, "\n";

=head1 DESCRIPTION

This is the next generation (for Bioperl) of representing Taxonomy
information.  Previously all information was managed by a single
object called Bio::Species.  This new implementation allows
representation of the intermediete nodes not just the species nodes
and can relate their connections.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl-dot-org

Describe contact details here

=head1 CONTRIBUTORS

Juguang Xiao, juguang@tll.org.sg

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::Taxonomy::Node;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::IdentifiableI;
use Bio::DB::Taxonomy;

@ISA = qw(Bio::Root::Root Bio::IdentifiableI  );

=head2 new

 Title   : new
 Usage   : my $obj = new Bio::Taxonomy::Node();
 Function: Builds a new Bio::Taxonomy::Node object 
 Returns : an instance of Bio::Taxonomy::Node
 Args    : -dbh       => a reference to a Bio::DB::Taxonomy object
           -name      => a string representing the node name
           -object_id => unique identifier - typically NCBI Taxid

=cut

sub new {
  my($class,@args) = @_;
  my $self = $class->SUPER::new(@args);
  my ($name,$uniqueid,$parentid,$rank,$div,$dbh, $factory) = 
      $self->_rearrange([qw(NAME OBJECT_ID PARENT_ID RANK DIVISION
			    DBH FACTORY)],
			@args);

  $uniqueid && $self->object_id($uniqueid);
  $name && $self->node_name($name);
  $rank && $self->rank($rank);
  $div  && $self->division($div);
  $factory && $self->factory($factory);
  unless(defined $factory){
      $self->db_handle($dbh 
        || Bio::DB::Taxonomy->new(-source => 'entrez'));
  }
  $self->parent_id($parentid);
  return $self;
}

=head2 db_handle

 Title   : db_handle
 Usage   : $obj->db_handle($newval)
 Function: Get/Set Bio::DB::Taxonomy Handle
 Returns : value of db_handle (a scalar) (Bio::DB::Taxonomy object)
 Args    : on set, new value (a scalar or undef, optional) Bio::DB::Taxonomy object


=cut

sub db_handle{
    my $self = shift;
    if( @_ ) {
	my $v = shift;
	# until we establish some other higher level TaxonomyDB interface
	if( ! ref($v) || ! $v->isa('Bio::DB::Taxonomy') ) {
	  $self->throw("Must have provided a valid Bio::DB::Taxonomy object");
	}
	$self->{'db_handle'} = $v;
    }
    return $self->{'db_handle'};
}

=head2 factory

  Title:    factory
  Usage:    $factory->factory($newval);
  Function: Get/Set Bio::Taxonomy::FactoryI implementation
  Returns:  Bio:;Taxonomy::FactoryI
  Args:     Bio::Taxonomy::FactoryI

=cut

sub factory {
    my $self = shift;
    if(@_){
        my $v = shift;
        unless(ref($v) || $v->isa('Bio::Taxonomy::FactoryI')){
            $self->throw('A Bio::Taxonomy::FactoryI object required');
        }
        $self->{_factory} = $v;
    }
    return $self->{_factory};
}

=head2 rank

 Title   : rank
 Usage   : $obj->rank($newval)
 Function: 
 Example : 
 Returns : value of rank (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub rank{
    my $self = shift;

    return $self->{'rank'} = shift if @_;
    return $self->{'rank'};
}

=head2 object_id

 Title   : object_id
 Usage   : $obj->object_id($newval)
 Function: 
 Example : 
 Returns : value of object_id (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub object_id {
    my $self = shift;

    return $self->{'object_id'} = shift if @_;
    return $self->{'object_id'};
}

*ncbi_taxid = \&object_id;

=head2 version

 Title   : version
 Usage   : $obj->version($newval)
 Function: 
 Example : 
 Returns : value of version (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub version{
    my $self = shift;

    return $self->{'version'} = shift if @_;
    return $self->{'version'};
}

=head2 authority

 Title   : authority
 Usage   : $obj->authority($newval)
 Function: 
 Example : 
 Returns : value of authority (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub authority{
    my $self = shift;

    return $self->{'authority'} = shift if @_;
    return $self->{'authority'};
}


=head2 namespace

 Title   : namespace
 Usage   : $obj->namespace($newval)
 Function: 
 Example : 
 Returns : value of namespace (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub namespace{
    my $self = shift;

    return $self->{'namespace'} = shift if @_;
    return $self->{'namespace'};
}

=head2 parent_id

 Title   : parent_id
 Usage   : $obj->parent_id($newval)
 Function: 
 Example : 
 Returns : value of parent_id (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub parent_id{
    my $self = shift;

    return $self->{'parent_id'} = shift if @_;
    return $self->{'parent_id'};
}

=head2 get_Parent_Node

 Title   : get_Parent_Node
 Usage   : my $parentnode = $node->get_Parent_Node()
 Function: Retrieve the full Parent node from the database
 Returns : Bio::Taxonomy::Node
 Args    : none


=cut

sub get_Parent_Node {
   my ($self) = @_;
   
   my $node = $self->db_handle->get_Taxonomy_Node(-taxonid => $self->parent_id);
   unless ( $node ) {
       $self->warn("Could not find node for parent id ". $self->parent_id);
       return undef;
   }
   return $node;
}

=head2 node_name

 Title   : node_name
 Usage   : $obj->node_name($newval)
 Function: 
 Example : 
 Returns : value of node_name (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub node_name{
    my $self = shift;
    return $self->{'node_name'} = shift if @_;
    return $self->{'node_name'};
}

=head2 classification

 Title   : classification
 Usage   : $self->classification(@class_array);
           @classification = $self->classification();
 Function: Fills Returns the classification list in
           the object.  The array provided must be in
           the order SPECIES, GENUS ---> KINGDOM.
           Checks are made that species is in lower case,
           and all other elements are in title case.
 Returns : Classification array
 Args    : none - this can be set directly

=cut

sub classification {
   my ($self,@vals) = @_;
   my $p;
   if( defined($p = $self->get_Parent_Node()) &&
	       $p->object_id != 1  ) {
       # okay this won't really work - need to do proper recursion
       push @vals, $p->classification;
   }
   if( $self->show_all || $self->rank ne 'no rank') {
       push @vals,$self->node_name();
   }
   return @vals;
}


=head2 division

 Title   : division
 Usage   : $obj->division($newval)
 Function: 
 Example : 
 Returns : value of division (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub division{
    my $self = shift;

    return $self->{'division'} = shift if @_;
    return $self->{'division'};
}

=head2 show_all

 Title   : show_all
 Usage   : $obj->show_all($newval)
 Function: Boolean flag whether or not we should show all intermediete
           nodes that do not have actual ranks.
 Returns : value of show_all (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub show_all{
    my $self = shift;

    return $self->{'show_all'} = shift if @_;
    return $self->{'show_all'};
}

=head2 name
  
  Title:    name
  Usage:    $obj->name('scientific', 'sapiens');
            $obj->name('common', 'human', 'man');
            my @names = @{$obj->name('common')};
  Function: Get and set the names
  Returns:  names (a array reference)
  Args:     Arg1 => the name_class. You can assign any text, but the words
                'scientific' and 'common' have the special meaning, as
                scientific name and common name, respectively.
            Arg2 .. => the names

=cut

sub name {
    my ($self, $name_class, @names) = @_;
    $self->throw('No name class specified') unless defined $name_class;
    # scientific name should be special, because of its uniqueness.
    return [$self->scientific_name(@names)] if $name_class =~ /scientific/i;
    $self->{_names_hash} = {} unless exists $self->{_names_hash};
    if(@names){
        $self->{_names_hash}->{$name_class} = [] 
            unless exists $self->{_names_hash}->{$name_class};
        push @{$self->{_names_hash}->{$name_class}}, @names;
    }
    return $self->{_names_hash}->{$name_class};
}

=head2 scientific_name

  Title:    scientific_name
  Usage:    my $new_val = $obj->scientific_name($newval);
  Function: Get/Set the scientific name
  Returns:  a scalar text value
  Args:     a scalar text value

=cut

sub scientific_name {
    my $self = shift;
    if(@_){
        my $scientific_name = shift;
        if(defined $self->{_scientific_name}){
            my $current = $self->{_scientific_name};
            $self->throw("Scientific name can be set once only![$current]");
        }
        return $self->{_scientific_name} = $scientific_name;
    }
    return $self->{_scientific_name};
}

=head2 parent_taxon_id

  Title   : parent_taxon_id
  Usage   : $self->parent_taxon_id($newval);
            $val = $self->parent_taxon_id;
  Function: Get/Set for parent_taxon_id
  Return  : 
  Args    :    

=cut

sub parent_taxon_id {
    my $self = shift;
    return $self->{_parent_taxon_id} = shift if @_;
    return $self->{_parent_taxon_id};
}

1; # EOF
