package MooX::Options::Role;

# ABSTRACT: role that is apply to your object
use strict;
use warnings;

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
    my %has_to_transform;

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
            $has_to_transform{$name} = Data::Record->new(
                { split => $data{autosplit}, unless => $RE{quoted} } );
            if ( my $short = $data{short} ) {
                $has_to_transform{$short} = $has_to_transform{${name}};
            }
            for ( my $i = 1; $i <= length($name); $i++ ) {
                my $long_short = substr( $name, 0, $i );
                $has_to_transform{$long_short} = $has_to_transform{${name}};
            }
        }
    }

    return \@options, \%has_to_transform;
}

sub _options_fix_argv {
    my ($option_data, $has_to_transform) = @_;

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

        my $arg_name = $dash;

        if (defined $negative) {
          if (exists $option_data->{$arg_name_without_dash} && $option_data->{$arg_name_without_dash}{negativable}) {
            $arg_name .= 'no-';
          } else {
            $arg_name .= 'no_';
          }
        }

        $arg_name .= $arg_name_without_dash;

        if ( my $rec = $has_to_transform->{$arg_name_without_dash} ) {
          $arg_values = shift @ARGV;
          foreach my $record ( $rec->records($arg_values) ) {
              #remove the quoted if exist to chain
              $record =~ s/^['"]|['"]$//gx;


              #####################################################################################
              # These anon-subs are for fetching the long arg_name from the short arg_name or the
              # 'shorter' (i.e. partial) arg_name. This appears neccesary as there doesn't seem to 
              # be a way to get the contents of $option_data without the long arg_name.
              my $long_from_short = sub {
                  my ($arg,$data) = @_;                  
                  foreach my $key ( keys %{$data} ) {
                      return $key if exists $data->{$key}->{short} && $data->{$key}->{short} eq $arg;
                  }

                  return undef;
              };

              my $long_from_shorter = sub {
                  my ($arg,$data) = @_;
                  my ($guess_arg, $guess_abort) = (undef, 0);
                  foreach my $key ( keys %{$data} ) {
                      return undef if $guess_abort > 1;
                      my $safe_arg = quotemeta($arg =~ s/-/_/gr);
                      if($key =~ m/^$safe_arg/) {
                        $guess_arg = $key;
                        $guess_abort++;
                      }
                  }
                  return $guess_arg;
              };
              #####################################################################################

              ####################################################################################################################
              # The long conditional is only looking for autorange => 1 in $option_data. It can likely be replaced
              # with something less ugly if there is a better way to get at the keys than using the anon-subs above.
              # If autorange => 1, then it splits on '..' and returns the eval'd range (1..4 => 1,2,3,4).
              # It already splits the records based on autosplit value (and sets it to ',' if it is not set) so ranges only 
              # need to be processed if they contain '..' (as no autosplit + autorange defaults autosplit => ',', the other normal 
              # range separator). Be careful to check exists on keys as vivification can mess up test results.
              my @records = ((  (exists $option_data->{$arg_name_without_dash} && exists $option_data->{$arg_name_without_dash}->{autorange} && $option_data->{$arg_name_without_dash}->{autorange})
                              ||(   $long_from_short->($arg_name_without_dash, $option_data) && exists $option_data->{$long_from_short->($arg_name_without_dash,$option_data)} 
                                    && exists $option_data->{$long_from_short->($arg_name_without_dash, $option_data)}->{autorange} && $option_data->{$long_from_short->($arg_name_without_dash, $option_data)}->{autorange})
                              ||(   $long_from_shorter->($arg_name_without_dash, $option_data) && exists $option_data->{$long_from_shorter->($arg_name_without_dash,$option_data)} 
                                    && exists $option_data->{$long_from_shorter->($arg_name_without_dash, $option_data)}->{autorange} && $option_data->{$long_from_shorter->($arg_name_without_dash, $option_data)}->{autorange})
                            ) && $record =~ m/^\d+(?:\.\.\d{0,})?$/)
                                ?(eval { 
                                    my ($start, $end) = split(/\.\./, $record);
                                    $end ||= $start;
                                    return ($start =~ /^\d+$/ && $end =~ /^\d*$/)?($start .. $end):undef;
                                })
                                :($record);
              ####################################################################################################################

              push( @new_argv, $arg_name, $_ ) for @records;
          }
        } else {
          push @new_argv, $arg_name;
        }
    }

    return @new_argv;

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

    my ($options, $has_to_transform) = _options_prepare_descriptive(\%options_data);

    local @ARGV = @ARGV if $options_config{protect_argv};
    @ARGV = _options_fix_argv(\%options_data, $has_to_transform);

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
    }

    my $prog_name = $class->_options_prog_name();

    # create usage str
    my $usage_str = "USAGE: $prog_name %o";

    my ( $opt, $usage ) = describe_options(
        ($usage_str), @$options,
        [ 'usage', 'show a short help message'],
        [ 'help|h', "show a help message" ],
        [ 'man', "show the manual" ],
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
                      carp $@;
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
