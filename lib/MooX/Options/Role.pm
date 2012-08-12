package MooX::Options::Role;

# ABSTRACT: role that is apply to your object
use strict;
use warnings;

# VERSION

=head1 USAGE

Don't use MooX::Options::Role directly. It is used by L<MooX::Options> to upgrade your module. But it is useless alone.

=cut

use MRO::Compat;
use Moo::Role;
use Getopt::Long 2.38;
use Getopt::Long::Descriptive 0.091;
use Regexp::Common;
use Data::Record;

=method new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=cut

sub new_with_options {
    my ( $class, @params ) = @_;
    return $class->new( $class->parse_options(@params) );
}

=method parse_options

Parse your options, call L<Getopt::Long::Descriptve> and convert the result for the "new" method.

It is use by "new_with_options".

=cut

## no critic qw/Modules::ProhibitExcessMainComplexity/
sub parse_options {
    my ( $class, %params ) = @_;
    my %metas          = $class->_options_meta;
    my %options_params = $class->_options_params;
    my @options;

    my $option_name = sub {
        my ( $name, %meta ) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $meta{short} if defined $meta{short};
        $cmdline_name .= '+' if $meta{repeatable} && !defined $meta{format};
        $cmdline_name .= '!' if $meta{negativable};
        $cmdline_name .= '=' . $meta{format} if defined $meta{format};
        return $cmdline_name;
    };

    my %has_to_split;
    for my $name ( keys %metas ) {
        my %meta = %{ $metas{$name} };
        my $doc  = $meta{doc};
        $doc = "no doc for $name" if !defined $doc;
        push @options, [ $option_name->( $name, %meta ), $doc ];
        $has_to_split{$name}
            = Data::Record->new(
            { split => $meta{autosplit}, unless => $RE{quoted} } )
            if defined $meta{autosplit};
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

    my @flavour;
    if ( defined $options_params{flavour} ) {
        push @flavour, { getopt_conf => $options_params{flavour} };
    }
    my ( $opt, $usage )
        = describe_options( ("USAGE: %c %o"), @options,
        [ 'help|h', "show this help message" ], @flavour );
    if ( $opt->help() || defined $params{help} ) {
        print $usage, "\n";
        my $exit_code = 0;
        $exit_code = 0 + $params{help} if defined $params{help};
        exit($exit_code);
    }

    my @missing_required;
    my %cmdline_params = %params;
    for my $name ( keys %metas ) {
        my %meta = %{ $metas{$name} };
        if ( !defined $cmdline_params{$name} ) {
            if ( defined( my $val = $opt->$name() ) ) {
                $cmdline_params{$name} = $val;
            }
        }
        push @missing_required, $name
            if $meta{required} && !defined $cmdline_params{$name};
    }

    if (@missing_required) {
        print join( "\n", ( map { $_ . " is missing" } @missing_required ),
            '' );
        print $usage, "\n";
        exit(1);
    }

    return %cmdline_params;
}
## use critic

sub _options_meta {
    my ( $class, @meta ) = @_;
    return $class->maybe::next::method(@meta);
}

sub _options_params {
    my ( $class, @params ) = @_;
    return $class->maybe::next::method(@params);
}

=method options_usage

Display help message.

Check full doc L<MooX::Options> for more details.

=cut

sub options_usage {
    my ( $self, $code, @messages ) = @_;
    $code = 0 if !defined $code;
    print join( "\n", @messages, '' ) if @messages;
    local @ARGV = ();
    return $self->parse_options( help => $code );
}

1;
