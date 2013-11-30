package MooX::Options::Descriptive::Usage;

# ABSTRACT: Usage class

=head1 DESCRIPTION

Usage class to display the error message.

This class use the full size of your terminal

=cut

use strict;
use warnings;
# VERSION
use feature 'say';
use Text::WrapI18N;
use Term::Size::Any qw/chars/;
use Getopt::Long::Descriptive;
use Scalar::Util qw/blessed/;

my %format_doc = (
    's'  => 'String',
    's@' => '[Strings]',
    'i'  => 'Int',
    'i@' => '[Ints]',
    'o'  => 'Ext. Int',
    'o@' => '[Ext. Ints]',
    'f'  => 'Real',
    'f@' => '[Reals]',
);

my %format_long_doc = (
    's'  => 'String',
    's@' => 'Array of Strings',
    'i'  => 'Integer',
    'i@' => 'Array of Integers',
    'o'  => 'Extended Integer',
    'o@' => 'Array of extended integers',
    'f'  => 'Real number',
    'f@' => 'Array of real numbers',
);


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
    my ($class, $args) = @_;

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
    my $sub_commands =  defined $self->{target} ? $self->{target}->_options_sub_commands() //
        [] : [];
    return if !@$sub_commands;
    return "", 'SUB COMMANDS AVAILABLE: ' . join(', ', @$sub_commands), "";
}

=method text

Return the full text help, leader and option text.

=cut
sub text {
    my ($self) = @_;

    return join("\n", $self->leader_text, $self->option_text, $self->sub_commands_text);
}

# set the column size of your terminal into the wrapper
sub _set_column_size {
    my ($columns) = chars();
    $columns //= 78;
    $columns = $ENV{TEST_FORCE_COLUMN_SIZE} if defined $ENV{TEST_FORCE_COLUMN_SIZE};
    $Text::WrapI18N::columns = $columns - 4;
    return;
}

=method option_text

Return the help message for your options

=cut
sub option_text {
    my ($self) = @_;
    my %options_data =  defined $self->{target} ?  $self->{target}->_options_data : ();
    my $getopt_options = $self->{options};
    my @message;
    _set_column_size;
    for my $opt(@$getopt_options) {
        my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        $format_doc_str = 'JSON' if defined $options_data{$opt->{name}}{json};
        push @message, (defined $short ? "-" . $short . " " : "") . "-" . (length($opt->{name}) > 1 ? "-" : "") . $opt->{name} . ":" . (defined $format_doc_str ? " " . $format_doc_str : "");
        push @message, wrap("    ", "        ", $opt->{desc});
        push @message, "";
    }

    return join("\n    ", "", @message);
}

=method option_pod

Return the usage message in pod format

=cut
sub option_pod {
    my ($self) = @_;

    my %options_data = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config = defined $self->{target} ? $self->{target}->_options_config : ();

    my $prog_name = $self->{prog_name} //
        Getopt::Long::Descriptive::prog_name;

    my $sub_commands = defined $self->{target} ? $self->{target}->_options_sub_commands() //
        [] : [];

    my @man = (
        "=head1 NAME",
        $prog_name,
    );

    if (defined (my $description = $options_config{description})) {
        push @man, "=head1 DESCRIPTION", $description;
    }

    push @man, (
        "=head1 SYNOPSIS",
        $prog_name . " [-h] [long options ...]",
    );

    if (defined (my $synopsis = $options_config{synopsis})) {
        push @man, $synopsis;
    }

    push @man, (
        "=head1 OPTIONS",
        "=over"
    );

    for my $opt(@{$self->{options}}) {

        my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_long_doc{$format} if defined $format;
        $format_doc_str = 'JSON' if defined $options_data{$opt->{name}}{json};
        
        my $opt_long_name = "-" . (length($opt->{name}) > 1 ? "-" : "") . $opt->{name};
        my $opt_name = (defined $short ? "-" . $short . " " : "") . $opt_long_name . ":" . (defined $format_doc_str ? " " . $format_doc_str : "");

        push @man, "=item B<".$opt_name.">";

        my $opt_data = $options_data{$opt->{name}} // {};
        push @man, $opt_data->{long_doc} // $opt->{desc};

    }
    push @man, "=back";

    if (@$sub_commands) {
        push @man, "=head1 AVAILABLE SUB COMMANDS";
        push @man, "=over";
        for my $sub_command(@$sub_commands) {
            push @man, (
                "=item B<" . $sub_command . "> :",
                $prog_name . " " . $sub_command . " [-h] [long options ...]",
            );
        }
        push @man, "=back";
    }

    if (defined (my $authors = $options_config{authors})) {
        if (!ref $authors && length($authors)) {
            $authors = [$authors];
        }
        if (@$authors) {
            push @man, (
                "=head1 AUTHORS",
                "=over"
            );
            push @man, map { "=item B<" . $_ . ">" } @$authors;
            push @man, "=back"
        }
    }

    return join("\n\n", @man);
}

=method option_short_usage

All options message without help

=cut
sub option_short_usage {
  my ($self) = @_;
  my %options_data =  defined $self->{target} ?  $self->{target}->_options_data : ();
  my $getopt_options = $self->{options};

  my $prog_name = $self->{prog_name} // Getopt::Long::Descriptive::prog_name;

  my @message;
  for my $opt(@$getopt_options) {
      my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
      my $format_doc_str;
      $format_doc_str = $format_doc{$format} if defined $format;
      push @message, "-" . (length($opt->{name}) > 1 ? "-" : "") . $opt->{name}
  }
  return join(" ", $prog_name, map { "[ $_ ]"} @message);
}

=method warn

Warn your options help message

=cut
sub warn { return CORE::warn shift->text }

=method die

Croak your options help message

=cut
sub die  { 
  my ($self) = @_;
  $self->{should_die} = 1;
  return;
}


use overload (
    q{""} => "text",
    '&{}' => sub {
    my ($self) = @_;
    return sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
  }
);

1;
