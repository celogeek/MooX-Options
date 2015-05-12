package MooX::Options::Descriptive::Usage;

# ABSTRACT: Usage class

=head1 DESCRIPTION

Usage class to display the error message.

This class use the full size of your terminal

=cut

use strict;
use warnings;

# VERSION
use feature 'say', 'state';
use Getopt::Long::Descriptive;
use Scalar::Util qw/blessed/;
use Locale::TextDomain 'MooX-Options';

my %format_doc = (
    's'  => __("String"),
    's@' => __("[Strings]"),
    'i'  => __("Int"),
    'i@' => __("[Ints]"),
    'o'  => __("Ext. Int"),
    'o@' => __("[Ext. Ints]"),
    'f'  => __("Real"),
    'f@' => __("[Reals]"),
);

sub _format_long_doc {
  my $format = shift;
  my %format_long_doc = (
      's'  => __("String"),
      's@' => __("Array of Strings"),
      'i'  => __("Integer"),
      'i@' => __("Array of Integers"),
      'o'  => __("Extended Integer"),
      'o@' => __("Array of extended integers"),
      'f'  => __("Real number"),
      'f@' => __("Array of real numbers"),
  );
  return $format_long_doc{$format};
}

=method new

The object is create with L<MooX::Options::Descriptive>.

Valid option is :

=over

=item leader_text

Text that appear on top of your message

=item options

The options spec of your message

=back

=cut

sub new {
    my ( $class, $args ) = @_;

    my %self;
    @self{qw/options leader_text/} = @$args{qw/options leader_text/};

    return bless \%self => $class;
}

=method leader_text

Return the leader_text.

=cut

sub leader_text { return shift->{leader_text} }

=method sub_commands_text

Return the list of sub commands if available.

=cut

sub sub_commands_text {
    my ($self) = @_;
    my $sub_commands = [];
    if (defined $self->{target} && defined (my $sub_commands_options = $self->{target}->_options_sub_commands)) {
      $sub_commands = $sub_commands_options;
    }
    return if !@$sub_commands;
    return "", __("SUB COMMANDS AVAILABLE: ") . join(', ', @$sub_commands), "";
}

=method text

Return a compact help message.

=cut

sub text {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );
    my $getopt_options = $self->{options};

    my $lf = _get_line_fold();


    my @to_fold;
    my $max_spec_length = 0;
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @to_fold, '';
            push @to_fold, $options_config{spacer} x ( $lf->config('ColMax') - 4 );
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};

        my $spec = ( defined $short ? "-" . $short . " " : "" ) . "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name}
            . ( defined $format_doc_str ? "=".$format_doc_str : "" );
        
        $max_spec_length = length($spec) if $max_spec_length < length($spec);

        push @to_fold, $spec, $opt->{desc};
    }

    my @message;
    while(@to_fold) {
      my $spec = shift @to_fold;
      my $desc = shift @to_fold;
      if (length($spec)) {
        push @message, $lf->fold("    ", " " x (6 + $max_spec_length), sprintf("%-" . ($max_spec_length+1) . "s %s", $spec, $desc));
      } else {
        push @message, $desc, "\n";
      }
    }

    return join("\n", $self->leader_text, "", join("", @message), $self->sub_commands_text);
}

# set the column size of your terminal into the wrapper
sub _get_line_fold {
  my $columns = $ENV{TEST_FORCE_COLUMN_SIZE}
  || eval {
        require Term::Size::Any;
        [Term::Size::Any::chars()]->[0];
  } || 80;

  require Text::LineFold;
  return Text::LineFold->new( ColMax => $columns - 4 );
}

=method option_text

Return the help message for your options

=cut

sub option_help {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );
    my $getopt_options = $self->{options};
    my @message;
    my $lf = _get_line_fold();
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @message, $options_config{spacer} x ( $lf->config('ColMax') - 4 );
            push @message, "";
            push @message, "";
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};
        push @message,
              ( defined $short ? "-" . $short . " " : "" ) . "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name} . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );
        
        my $opt_data = $options_data{ $opt->{name} };
        $opt_data = {} if !defined $opt_data;
        push @message, $lf->fold( "    ", "        ", defined $opt_data->{long_doc} ? $opt_data->{long_doc} : $opt->{desc} );
        push @message, "";
    }

    return join("\n", $self->leader_text, join( "\n    ", "", @message ), $self->sub_commands_text);
}

=method option_pod

Return the usage message in pod format

=cut

sub option_pod {
    my ($self) = @_;

    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target}
        ? $self->{target}->_options_config
        : ( spacer => " " );

    my $prog_name = $self->{prog_name};
    $prog_name = Getopt::Long::Descriptive::prog_name if !defined $prog_name;

    my $sub_commands = [];
    if (defined $self->{target} && defined (my $sub_commands_options = $self->{target}->_options_sub_commands())) {
      $sub_commands = $sub_commands_options;
    }

    my @man = ( "=encoding UTF-8", "=head1 NAME", $prog_name, );

    if ( defined( my $description = $options_config{description} ) ) {
        push @man, "=head1 DESCRIPTION", $description;
    }

    push @man,
        ( "=head1 SYNOPSIS", $prog_name . " [-h] [" . __("long options ...") ."]");

    if ( defined( my $synopsis = $options_config{synopsis} ) ) {
        push @man, $synopsis;
    }

    push @man, ( "=head1 OPTIONS", "=over" );

    my $spacer_escape = "E<" . ord($options_config{spacer}) . ">";
    for my $opt ( @{ $self->{options} } ) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @man, "=back";
            push @man, $spacer_escape x 40;
            push @man, "=over";
            next;
        }
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = _format_long_doc($format) if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};

        my $opt_long_name
            = "-" . ( length( $opt->{name} ) > 1 ? "-" : "" ) . $opt->{name};
        my $opt_name
            = ( defined $short ? "-" . $short . " " : "" )
            . $opt_long_name . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );

        push @man, "=item B<" . $opt_name . ">";

        my $opt_data = $options_data{ $opt->{name} };
        $opt_data = {} if !defined $opt_data;
        push @man, defined $opt_data->{long_doc} ? $opt_data->{long_doc} : $opt->{desc};
    }
    push @man, "=back";

    if (@$sub_commands) {
        push @man, "=head1 AVAILABLE SUB COMMANDS";
        push @man, "=over";
        for my $sub_command (@$sub_commands) {
            push @man, ( "=item B<" . $sub_command . "> :", $prog_name . " " . $sub_command ." [-h] [" . __("long options ...") ."]");
        }
        push @man, "=back";
    }

    if ( defined( my $authors = $options_config{authors} ) ) {
        if ( !ref $authors && length($authors) ) {
            $authors = [$authors];
        }
        if (@$authors) {
            push @man, ( "=head1 AUTHORS", "=over" );
            push @man, map { "=item B<" . $_ . ">" } @$authors;
            push @man, "=back";
        }
    }

    return join( "\n\n", @man );
}

=method option_short_usage

All options message without help

=cut

sub option_short_usage {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my $getopt_options = $self->{options};

    my $prog_name = $self->{prog_name};
    $prog_name = Getopt::Long::Descriptive::prog_name if !defined $prog_name;

    my @message;
    for my $opt (@$getopt_options) {
        if ( $opt->{desc} eq 'spacer' ) {
            push @message, '';
            next;
        }
        my ($format) = $opt->{spec} =~ /(?:\|\w)?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};
        push @message,
              "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name}
            . ( defined $format_doc_str ? "=" . $format_doc_str : "" );
    }
    return
        join( " ", $prog_name, map { $_ eq '' ? " | " : "[ $_ ]" } @message );
}

=method warn

Warn your options help message

=cut

sub warn { return CORE::warn shift->text }

=method die

Croak your options help message

=cut

sub die {
    my ($self) = @_;
    $self->{should_die} = 1;
    return;
}

use overload (
    q{""} => "text",
    '&{}' => sub {
        return
            sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
    }
);

1;
