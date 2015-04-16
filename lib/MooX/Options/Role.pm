package MooX::Options::Role;

# ABSTRACT: role that is apply to your object
use strict;
use warnings;

use Locale::TextDomain qw(MooX-Options);

# VERSION

=head1 USAGE

Don't use MooX::Options::Role directly. It is used by L<MooX::Options> to upgrade your module. But it is useless alone.

=cut

use MRO::Compat;
use MooX::Options::Descriptive;
use Regexp::Common;
use Data::Record;
use JSON;
use Carp;
use Pod::Usage qw/pod2usage/;
use Path::Class 0.32;
use Scalar::Util qw/blessed/;

### PRIVATE

sub _option_name {
    my ( $name, %data ) = @_;
    my $cmdline_name = join('|', grep {defined} ($name, $data{short}));
    $cmdline_name .= '+' if $data{repeatable} && !defined $data{format};
    $cmdline_name .= '!' if $data{negativable};
    $cmdline_name .= '=' . $data{format} if defined $data{format};
    return $cmdline_name;
}

sub _options_prepare_descriptive {
    my ($options_data) = @_;

    my @options;
    my %all_options;
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
		my $option = {};
		$option->{hidden} = 1 if $data{hidden};

        push @options, [ _option_name( $name, %data ), $doc, $option ];

        push @{$all_options{$name}}, $name;
        for ( my $i = 1; $i <= length($name); $i++ ) {
          my $long_short = substr( $name, 0, $i );
          push @{$all_options{$long_short}}, $name if !exists $options_data->{$long_short};
        }

        if ( defined $data{autosplit} ) {
            $has_to_split{$name} = Data::Record->new(
                { split => $data{autosplit}, unless => $RE{quoted} } );
            if ( my $short = $data{short} ) {
                $has_to_split{$short} = $has_to_split{${name}};
            }
            for ( my $i = 1; $i <= length($name); $i++ ) {
                my $long_short = substr( $name, 0, $i );
                $has_to_split{$long_short} = $has_to_split{${name}};
            }
        }
    }

    return \@options, \%has_to_split, \%all_options;
}

## no critic (ProhibitExcessComplexity)
sub _options_fix_argv {
    my ($option_data, $has_to_split, $all_options) = @_;

    my @new_argv;
    #parse all argv
    while(defined (my $arg = shift @ARGV)) {
        if ($arg eq '--') {
            push @new_argv, $arg, @ARGV;
            last;
        }
        if (index($arg, '-') != 0) {
            push @new_argv, $arg;
            next;
        }

        my ( $arg_name_with_dash, $arg_values ) = split( /=/x, $arg, 2 );
        if (index($arg_name_with_dash, '--') < 0 && !defined $arg_values) {
          $arg_values = length($arg_name_with_dash) > 2 ? substr($arg_name_with_dash, 2) : undef;
          $arg_name_with_dash = substr($arg_name_with_dash, 0, 2);
        }
        unshift @ARGV, $arg_values if defined $arg_values;

        my ($dash, $negative, $arg_name_without_dash) = $arg_name_with_dash =~ /^(\-+)(no\-)?(.*)$/x;
        $arg_name_without_dash =~ s/\-/_/gx;

        my $original_long_option = $all_options->{$arg_name_without_dash};
        if (defined $original_long_option) {
          if (@$original_long_option == 1) {
            $original_long_option = $original_long_option->[0];
          } else {
            $original_long_option = undef;
          }
        }

        my $arg_name = $dash;

        if (defined $negative && defined $original_long_option) {
          if (exists $option_data->{$original_long_option} && $option_data->{$original_long_option}{negativable}) {
            $arg_name .= 'no-';
          } else {
            $arg_name .= 'no_';
          }
        }

        $arg_name .= $arg_name_without_dash;

        if ( my $rec = $has_to_split->{$arg_name_without_dash} ) {
			if ($arg_values = shift @ARGV) {
				my $autorange = defined $original_long_option && exists $option_data->{$original_long_option} && $option_data->{$original_long_option}{autorange};
				foreach my $record ( $rec->records($arg_values) ) {
					#remove the quoted if exist to chain
					$record =~ s/^['"]|['"]$//gx;
					if ($autorange) {
						push @new_argv, map { $arg_name => $_ } _expand_autorange($record);
					} else {
						push @new_argv, $arg_name, $record;
					}
				}
			}
        } else {
          push @new_argv, $arg_name;
        }

        # if option has an argument, we keep the argument untouched
        if (defined $original_long_option && (my $opt_data = $option_data->{$original_long_option})) {
          if ($opt_data->{format}) {
            push @new_argv, shift @ARGV;
          }          
        }
    }

    return @new_argv;
}
## use critic

sub _expand_autorange {
	my ($arg_value) = @_;

	my @expanded_arg_value;
	my ($left_figure, $autorange_found, $right_figure) = $arg_value =~ /^(\d*)(\.\.)(\d*)$/x;
	if ($autorange_found) {
		$left_figure = $right_figure if !defined $left_figure || !length($left_figure);
		$right_figure = $left_figure if !defined $right_figure || !length($right_figure);
		if (defined $left_figure && defined $right_figure) {
			push @expanded_arg_value, $left_figure..$right_figure;
		}
	}
	return @expanded_arg_value ? @expanded_arg_value : $arg_value;
}

### PRIVATE

use Moo::Role;

requires qw/_options_data _options_config/;

=method new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=cut

sub new_with_options {
    my ( $class, %params ) = @_;

    #save subcommand

    if (ref (my $command_chain = $params{command_chain}) eq 'ARRAY') {
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

    if (ref (my $command_commands = $params{command_commands}) eq 'HASH') {
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
    if ($cmdline_params{usage}) {
        return $class->options_short_usage($params{usage}, $cmdline_params{usage});
    }

    my $self;
    return $self
      if eval { $self = $class->new( %cmdline_params ); 1 };
    if ( $@ =~ /^Attribute\s\((.*?)\)\sis\srequired/x ) {
        print STDERR "$1 is missing\n";
    }
    elsif ( $@ =~ /^Missing\srequired\sarguments:\s(.*)\sat\s\(/x ) {
        my @missing_required = split /,\s/x, $1;
        print STDERR
          join( "\n", ( map { $_ . " is missing" } @missing_required ), '' );
    }
    elsif ($@ =~ /^(.*?)\srequired/x) {
        print STDERR "$1 is missing\n";
    }
    elsif ($@ =~ /^isa\scheck.*?failed:\s/x) {
		print STDERR substr($@, index($@, ':') + 2);
    }
    else {
        print STDERR $@;
    }
    %cmdline_params = $class->parse_options( help => 1 );
    return $class->options_usage(1, $cmdline_params{help});
}

=method parse_options

Parse your options, call L<Getopt::Long::Descriptive> and convert the result for the "new" method.

It is use by "new_with_options".

=cut

sub parse_options {
    my ( $class, %params ) = @_;

    my %options_data   = $class->_options_data;
    my %options_config = $class->_options_config;
    if (defined $options_config{skip_options}) {
        delete @options_data{@{$options_config{skip_options}}};
    }

    my ($options, $has_to_split, $all_options) = _options_prepare_descriptive(\%options_data);

    local @ARGV = @ARGV if $options_config{protect_argv};
    @ARGV = _options_fix_argv(\%options_data, $has_to_split, $all_options);

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
    }

    my $prog_name = $class->_options_prog_name();

    # create usage str
    my $usage_str = $options_config{usage_string} // __x("USAGE: {prog_name} %o", prog_name => $prog_name );

    my ( $opt, $usage ) = describe_options(
        ($usage_str), @$options,
        [ 'usage',  __"show a short help message"],
        [ 'help|h', __"show a help message" ],
        [ 'man',    __"show the manual" ],
        ,@flavour
    );

    $usage->{prog_name} = $prog_name;
    $usage->{target} = $class;

    if ($usage->{should_die}) {
      return $class->options_usage(1, $usage);
    }

    my %cmdline_params = %params;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name}
            || $options_config{prefer_commandline} )
        {
            my $val = $opt->$name();
            if ( defined $val ) {
                if ( $data{json} ) {
                    if (! eval { $cmdline_params{$name} = decode_json($val); 1 }) {
                      print STDERR $@;
                      return $class->options_usage(1, $usage);
                    }
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

    if (   $opt->usage() || defined $params{usage}
    ) {
        $cmdline_params{usage} = $usage;
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
    if (!$usage) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    my $message = "";
    $message .= join( "\n", @messages, '' ) if @messages;
    $message .= $usage . "\n";
    if ($code > 0) {
      CORE::warn $message;
    } else {
      print $message;
    }
    exit($code) if $code >= 0;
    return;
}

=method options_short_usage

Display quick usage message, with only the list of options

=cut

sub options_short_usage {
  my ($class, $code, $usage) = @_;
    $code = 0 if !defined $code;

    if (!defined $usage || ! ref $usage) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    };
    my $message = "USAGE: " . $usage->option_short_usage . "\n";
    if ($code > 0) {
      CORE::warn $message;
    } else {
      print $message;
    }
    exit($code) if $code >= 0;
    return;
}

=method options_man

Display a pod like a manual

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
    $man_file->spew(iomode => '>:encoding(UTF-8)', $usage->option_pod);

    pod2usage(-verbose => 2, -input => $man_file->stringify, -exitval => 'NOEXIT', -output => $output);

    exit(0);
}

### PRIVATE NEED TO BE EXPORTED

sub _options_prog_name {
    return Getopt::Long::Descriptive::prog_name;
}

sub _options_sub_commands {
    return;
}

### PRIVATE NEED TO BE EXPORTED

1;
