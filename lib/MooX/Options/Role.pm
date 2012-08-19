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


requires qw/_options_data _options_config/;


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
    my %options_data          = $class->_options_data;
    my %options_config = $class->_options_config;
    my @skip_options;
    @skip_options = @{$options_config{skip_options}} if defined $options_config{skip_options};
    if ( @skip_options ) {
        delete @options_data{@skip_options};
    }
    my @options;

    my $option_name = sub {
        my ( $name, %data ) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $data{short} if defined $data{short};
        $cmdline_name .= '+' if $data{repeatable} && !defined $data{format};
        $cmdline_name .= '!' if $data{negativable};
        $cmdline_name .= '=' . $data{format} if defined $data{format};
        return $cmdline_name;
    };

    my %has_to_split;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;
        push @options, [ $option_name->( $name, %data ), $doc ];
        $has_to_split{$name}
            = Data::Record->new(
            { split => $data{autosplit}, unless => $RE{quoted} } )
            if defined $data{autosplit};
    }

    local @ARGV = @ARGV if $options_config{protect_argv};
    if (%has_to_split) {
        my @new_argv;

        #parse all argv
        for my $i (0..$#ARGV) {
            my $arg = $ARGV[$i];
            my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
            $arg_name =~ s/^--?//x;
            unless(defined $arg_values) {
                $arg_values = $ARGV[++$i];
            }
            if ( my $rec = $has_to_split{$arg_name} ) {
                foreach my $record ( $rec->records($arg_values) ) {

                    #remove the quoted if exist to chain
                    $record =~ s/^['"]|['"]$//gx;
                    push @new_argv, "--$arg_name", $record;
                }
            }
            else {
                push @new_argv, $arg;
            }
        }
        @ARGV = @new_argv;
    }

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
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
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name} ) {
            my $val = $opt->$name();
            if ( defined $val ) {
                $cmdline_params{$name} = $val;
            }
        }
        push @missing_required, $name
            if $data{required} && !defined $cmdline_params{$name};
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
