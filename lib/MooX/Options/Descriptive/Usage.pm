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

=method text

Return the full text help, leader and option text.

=cut
sub text {
    my ($self) = @_;

    return join("\n", $self->leader_text, $self->option_text);
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
    my $options = $self->{options};

    my @message;
    _set_column_size;
    for my $opt(@$options) {
        my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        push @message, (defined $short ? "-" . $short . " " : "") . "-" . (length($opt->{name}) > 1 ? "-" : "") . $opt->{name} . ":" . (defined $format_doc_str ? " " . $format_doc_str : "");
        push @message, wrap("    ", "        ", $opt->{desc});
        push @message, "";
    }

    return join("\n    ", "", @message);
}

=method warn

Warn your options help message

=cut
sub warn { return CORE::warn shift->text }

=method die

Croak your options help message

=cut
sub die  { return CORE::die  shift->text }


use overload (
    q{""} => "text",
    '&{}' => sub {
    my ($self) = @_;
    return sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
  }
);

1;
