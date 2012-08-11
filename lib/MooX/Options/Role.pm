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
use Regexp::Common;
use Data::Record;

sub new_with_options {
    my $class = shift;
    $class->new( $class->parse_options(@_) );
}

sub parse_options {
    my ( $class, %params ) = @_;
    my %metas = $class->_options_meta;
    my %options_params = $class->_options_params;
    my @options;
    my %cmdline_params;

    my $option_name = sub {
        my ($name, %meta) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $meta{short} if defined $meta{short};
        $cmdline_name .= '+' if $meta{repeatable} && ! defined $meta{format};
        $cmdline_name .= '!' if $meta{negativable};
        $cmdline_name .= '=' . $meta{format} if defined $meta{format};
        return $cmdline_name;
    };

    my %has_to_split;
    for my $name(keys %metas) {
        my %meta = %{$metas{$name}};
        push @options, [$option_name->($name, %meta), $meta{doc} // "no doc for $name"];
        $has_to_split{$name} = Data::Record->new({ split => $meta{autosplit}, unless => $RE{quoted} } ) if defined $meta{autosplit};
    }

    local @ARGV = @ARGV if $options_params{protect_argv};
    if (%has_to_split) {
        my @new_argv;
        #parse all argv
        for my $arg (@ARGV) {
            my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
            $arg_name =~ s/^--?//x;
            if ( my $rec = $has_to_split{$arg_name} ) {
                foreach my $record ( $rec->records($arg_values) ) {

                    #remove the quoted if exist to chain
                    $record =~ s/^['"]|['"]$//gx;
                    push @new_argv, "--$arg_name=$record";
                }
            }
            else {
                push @new_argv, $arg;
            }
        }
        @ARGV = @new_argv;
    }

    my ($opt, $usage) = describe_options(
        ("USAGE: %c %o"),
        @options,
        ['help|h', "show this help message"],
        { getopt_conf => $options_params{flavour} // [] },
    );
    if ($opt->help() || defined $params{help}) {
        print $usage,"\n";
        exit(0 + ($params{help} // 0));
    }

    my @missing_required;
    for my $name(keys %metas) {
        my %meta = %{$metas{$name}};
        $cmdline_params{$name} = $params{$name} // $opt->$name(); 
        push @missing_required, $name if $meta{required} && !defined $cmdline_params{$name};
    }

    if (@missing_required) {
        print join("\n", map { $_ . " is missing" } @missing_required,'') if @missing_required;
        print $usage,"\n";
        exit(1);
    }

    return %cmdline_params;
}

sub _options_meta {
    my ($class) = @_;
    shift->maybe::next::method(@_);
}

sub _options_params {
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
