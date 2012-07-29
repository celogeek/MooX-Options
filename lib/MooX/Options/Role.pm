package MooX::Options::Role;

# ABSTRACT: role that is apply to your object
use strict;
use warnings;

# VERSION

=head1 TODO

Write a doc

=cut

use MRO::Compat;
use Moo::Role;

use Carp;
use Data::Dumper;

sub new_with_options {
    my $class = shift;
    $class->new( $class->parse_options(@_) );
}

sub parse_options {
    my ( $class, %params ) = @_;
    my %option_information = shift->option_information;

    #carp Dumper \%option_info;
    return %params;
}

sub option_information {
    my ($class) = @_;
    carp "class $class";
    shift->maybe::next::method(@_);
}

1;
