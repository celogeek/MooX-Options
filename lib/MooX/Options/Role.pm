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
use Getopt::Long 2.38;
use Getopt::Long::Descriptive 0.091;

sub new_with_options {
    my $class = shift;
    $class->new( $class->parse_options(@_) );
}

sub parse_options {
    my ( $class, %params ) = @_;
    my %meta = shift->_options_meta;
    my @options;
    my %cmdline_params;

    for my $name(keys %meta) {
        my %options = %{$meta{$name}};
        my $option_name = $name;
        $option_name .= '|' . $options{short} if defined $options{short};
        my $doc = $options{doc} // $options{documentation} // "no doc for $name";
        push @options, [$option_name, $doc];
    }

    my ($opt, $usage) = describe_options(
        ("USAGE: %c %o"),
        @options,
        ['help|h', "show this help message"]
    );
    if ($opt->help()) {
        print $usage,"\n";
        exit(0);
    }

    for my $name(keys %meta) {
        $cmdline_params{$name} = $opt->$name(); 
    }

    return (%cmdline_params, %params);
}

sub _options_meta {
    my ($class) = @_;
    shift->maybe::next::method(@_);
}

1;
