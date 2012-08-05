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

    my $option_name = sub {
        my ($name, %options) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $options{short} if defined $options{short};
        $cmdline_name .= '+' if $options{repeatable} && ! defined $options{format};
        $cmdline_name .= '!' if $options{negativable};
        $cmdline_name .= '=' . $options{format} if defined $options{format};
        return $cmdline_name;
    };

    for my $name(keys %meta) {
        my %options = %{$meta{$name}};
        push @options, [$option_name->($name, %options), $options{doc} // "no doc for $name"];
    }

    my ($opt, $usage) = describe_options(
        ("USAGE: %c %o"),
        @options,
        ['help|h', "show this help message"]
    );
    if ($opt->help() || defined $params{help}) {
        print $usage,"\n";
        exit(0 + ($params{help} // 0));
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

sub options_usage {
    my ($self, $code, @messages) = @_;
    print join("\n", @messages,'') if @messages;
    local @ARGV = ();
    return $self->parse_options(help => $code // 0);
};

1;
