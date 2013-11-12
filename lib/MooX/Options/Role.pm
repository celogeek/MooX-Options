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
use MooX::Options::Descriptive;
use Regexp::Common;
use Data::Record;
use JSON;
use Carp;
use Pod::Usage qw/pod2usage/;
use Path::Class;
use Scalar::Util qw/blessed/;

requires qw/_options_data _options_config/;

=method new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=cut

sub new_with_options {
    my ( $class, %params ) = @_;
    
    #save subcommand
    
    if (ref (my $command_chain = delete $params{command_chain}) eq 'ARRAY') {
        $class->can('around')->(
             _options_prog_name => sub {
                my $prog_name = Getopt::Long::Descriptive::prog_name;
                for my $cmd (@$command_chain) {
                    next if !blessed $cmd || !$cmd->can('command_name');
                    if (defined (my $cmd_name = $cmd->command_name)) {
                        $prog_name .= ' ' . $cmd_name;
                    }
                }
                
                return $prog_name;    
             }
         );
    }

    if (ref (my $command_commands = delete $params{command_commands}) eq 'HASH') {
        $class->can('around')->(
             _options_sub_commands => sub {
                return [sort keys %$command_commands];
             }
         );
    }

    my %cmdline_params = $class->parse_options(%params);

    if ($cmdline_params{help}) {
        return $class->options_usage($params{help}, $cmdline_params{help});
    }
    if ($cmdline_params{man}) {
        return $class->options_man($cmdline_params{man});
    }

    my $self;
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

sub parse_options {
    my ( $class, %params ) = @_;

    my %options_data   = $class->_options_data;
    my %options_config = $class->_options_config;
    if (defined $options_config{skip_options}) {
        delete @options_data{@{$options_config{skip_options}}};
    }

    my ($options, $has_to_split) = _options_prepare_descriptive(\%options_data);

    local @ARGV = @ARGV if $options_config{protect_argv};
    @ARGV = _options_split_with($has_to_split) if %$has_to_split;

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
    }

    my $prog_name = $class->_options_prog_name();

    # create usage str
    my $usage_str = "USAGE: $prog_name %o";

    my ( $opt, $usage ) = describe_options(
        ($usage_str), @$options,
        [ 'help|h', "show this help message" ],
        [ 'man', "show the manual" ],
        ,@flavour
    );

    $usage->{prog_name} = $prog_name;
    $usage->{sub_commands} = $class->_options_sub_commands();

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

    if (   $opt->help() || defined $params{help}
    ) {
        $cmdline_params{help} = $usage;
    }

    if (   $opt->man() || defined $params{man}
    ) {
        $cmdline_params{man} = $usage;
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
    if (@messages && ref $messages[-1] eq 'MooX::Options::Descriptive::Usage') {
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

=method options_man

Display a pod like a manuel

=cut

sub options_man {
    my ($class, $usage, $output) = @_;
    local @ARGV = ();
    if (!$usage) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( man => 1 );
        $usage = $cmdline_params{man};
    }

    my $man_file = file(Path::Class::tempdir(CLEANUP => 1), 'help.pod');
    $man_file->spew($usage->option_pod($class));

    pod2usage(-verbose => 2, -input => $man_file->stringify, -exitval => 'NOEXIT', -output => $output);

    exit(0);
}

sub _option_name {
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
}

sub _options_prepare_descriptive {
    my ($options_data) = @_;

    my @options;
    my %has_to_split;

    for my $name (sort {
            $options_data->{$a}{order} <=> $options_data->{$b}{order}    # sort by order
              or $a cmp $b                                           # sort by attr name
        } keys %$options_data
      )
    {
        my %data = %{ $options_data->{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;

        push @options, [ _option_name( $name, %data ), $doc ];
        
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

    return \@options, \%has_to_split;
}

sub _options_split_with {
    my ($has_to_split) = @_;

    my @new_argv;
    #parse all argv
    for my $i ( 0 .. $#ARGV ) {
        my $arg = $ARGV[$i];
        my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
        unless ( defined $arg_values ) {
            $arg_values = $ARGV[ ++$i ];
        }
        if ( my $rec = $has_to_split->{$arg_name} ) {
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
    
    return @new_argv;

}

sub _options_prog_name {
    return Getopt::Long::Descriptive::prog_name;
}

sub _options_sub_commands {
    return;
}
1;