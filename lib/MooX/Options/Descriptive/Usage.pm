package MooX::Options::Descriptive::Usage;

# ABSTRACT: Usage class

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

sub new {
	my ($class, $args) = @_;

	my %self;
	@self{qw/options leader_text/} = @$args{qw/options leader_text/};

	return bless \%self => $class;
}

sub leader_text { return shift->{leader_text} }

sub text {
	my ($self) = @_;

	return join("\n", $self->leader_text, $self->option_text);
}

sub _set_column_size {
	my ($columns, $rows) = chars();
	$columns //= 78;
	$Text::WrapI18N::columns = $columns - 4;
	return;
}

sub option_text {
	my ($self) = @_;
	my $options = $self->{options};

	my @message;
	_set_column_size;
	for my $opt(@$options) {
		my ($short, $format) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
		my $format_doc_str;
		$format_doc_str = $format_doc{$format} if defined $format;
		push @message, (defined $short ? "-" . $short . " " : "") . "--" . $opt->{name} . ":" . (defined $format_doc_str ? " " . $format_doc_str : "");
		push @message, wrap("    ", "        ", $opt->{desc});
		push @message, "";
	}

	return join("\n    ", "", @message);
}

sub warn { return CORE::warn shift->text }
sub die  { return CORE::die  shift->text }


use overload (
	q{""} => "text",
	'&{}' => sub {
    my ($self) = @_;
    return sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
  }
);

1;
