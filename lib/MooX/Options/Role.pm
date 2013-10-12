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
use JSON;
use Carp;

requires qw/_options_data _options_config/;

=method new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=cut

sub new_with_options {
    my ( $class, %params ) = @_;
    my $self;
    my %cmdline_params = $class->parse_options(%params);

    if ($cmdline_params{help}) {
        return $class->options_usage($params{help}, $cmdline_params{help});
    }

    return $self
      if eval { $self = $class->new( %cmdline_params ); 1 };
    if ( $@ =~ /^Attribute\s\((.*?)\)\sis\srequired/x ) {
        print "$1 is missing\n";
    }
    elsif ( $@ =~ /^Missing\srequired\sarguments:\s(.*)\sat\s\(/x ) {
        my @missing_required = split /,\s/x, $1;
        print
          join( "\n", ( map { $_ . " is missing" } @missing_required ), '' );
    } elsif ($@ =~ /^(.*?)\srequired/x) {
        print "$1 is missing\n";
    }
    else {
        croak $@;
    }
    %cmdline_params = $class->parse_options( help => 1 );
    return $class->options_usage(1, $cmdline_params{help});
}

=method parse_options

Parse your options, call L<Getopt::Long::Descriptve> and convert the result for the "new" method.

It is use by "new_with_options".

=cut

## no critic qw/Modules::ProhibitExcessMainComplexity/
sub parse_options {
    my ( $class, %params ) = @_;
    my %options_data   = $class->_options_data;
    my %options_config = $class->_options_config;
    my @skip_options;
    @skip_options = @{ $options_config{skip_options} }
      if defined $options_config{skip_options};
    if (@skip_options) {
        delete @options_data{@skip_options};
    }
    my @options;

    my $option_name = sub {
        my ( $name, %data ) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $data{short} if defined $data{short};

        #dash name support
        my $dash_name = $name;
        $dash_name =~ tr/_/-/;
        if ( $dash_name ne $name ) {
            $cmdline_name .= '|' . $dash_name;
        }

        $cmdline_name .= '+' if $data{repeatable} && !defined $data{format};
        $cmdline_name .= '!' if $data{negativable};
        $cmdline_name .= '=' . $data{format} if defined $data{format};
        return $cmdline_name;
    };

    my %format_doc = (
        's'  => ' String',
        's@' => '[Strings]',
        'i'  => ' Int',
        'i@' => '[Ints]',
        'o'  => ' Ext. Int',
        'o@' => '[Ext. Ints]',
        'f'  => ' Real',
        'f@' => '[Reals]',
    );

    my %has_to_split;
    for my $name (
        sort {
            $options_data{$a}{order}
              <=> $options_data{$b}{order}    # sort by order
              or $a cmp $b                    # sort by attr name
        } keys %options_data
      )
    {
        my %data = %{ $options_data{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;
        my $format_doc_str = $data{format} // ' None';
        $format_doc_str = $format_doc{$format_doc_str}
          if defined $format_doc{$format_doc_str};
        $doc = "( " . sprintf( "%-11s", $format_doc_str ) . " ), " . $doc;

        push @options, [ $option_name->( $name, %data ), $doc ];
        if ( defined $data{autosplit} ) {
            $has_to_split{"--${name}"} = Data::Record->new(
                { split => $data{autosplit}, unless => $RE{quoted} } );
            if ( my $short = $data{short} ) {
                $has_to_split{"-${short}"} = $has_to_split{"--${name}"};
            }
            for ( my $i = 1; $i < length($name); $i++ ) {
                my $long_short = substr( $name, 0, $i );
                $has_to_split{"--${long_short}"} = $has_to_split{"--${name}"};
            }
        }
    }

    local @ARGV = @ARGV if $options_config{protect_argv};
    if (%has_to_split) {
        my @new_argv;

        #parse all argv
        for my $i ( 0 .. $#ARGV ) {
            my $arg = $ARGV[$i];
            my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
            unless ( defined $arg_values ) {
                $arg_values = $ARGV[ ++$i ];
            }
            if ( my $rec = $has_to_split{$arg_name} ) {
                foreach my $record ( $rec->records($arg_values) ) {

                    #remove the quoted if exist to chain
                    $record =~ s/^['"]|['"]$//gx;
                    push @new_argv, $arg_name, $record;
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
    my ( $opt, $usage ) = describe_options(
        ("USAGE: %c %o"), @options,
        [ 'help|h', "show this help message" ], @flavour
    );

    my %cmdline_params = %params;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name}
            || $options_config{prefer_commandline} )
        {
            my $val = $opt->$name();
            if ( defined $val ) {
                if ( $data{json} ) {
                    $cmdline_params{$name} = decode_json($val);
                }
                else {
                    $cmdline_params{$name} = $val;
                }
            }
        }
    }

    if ( $opt->help() || defined $params{help} ) {
        $cmdline_params{help} = $usage;
    }

    return %cmdline_params;
}
## use critic

=method options_usage

Display help message.

Check full doc L<MooX::Options> for more details.

=cut

sub options_usage {
    my ( $class, $code, @messages ) = @_;
    my $usage;
    if (@messages && ref $messages[-1] eq 'Getopt::Long::Descriptive::Usage') {
        $usage = shift @messages;
    }
    $code = 0 if !defined $code;
    print join( "\n", @messages, '' ) if @messages;
    if (!$usage) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    print $usage . "\n";
    exit($code) if $code >= 0;
    return;
}

1;
