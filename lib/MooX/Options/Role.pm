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

sub new_with_options {
    my $class = shift;
    $class->new( $class->parse_options(@_) );
}

sub parse_options {
    my ( $class, %params ) = @_;
    my %meta = shift->_options_meta;
    my @options = ("USAGE: %c %o");
    my %cmdline_params;

    return (%cmdline_params, %params);
}

sub _options_meta {
    my ($class) = @_;
    shift->maybe::next::method(@_);
}

1;
