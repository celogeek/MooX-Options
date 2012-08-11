package MooX::Options;

# ABSTRACT: add option keywords to your object (Mo/Moo/Moose)

=head1 MooX::Options

Use Getopt::Long::Descritive to provide command line option for your Mo/Moo/Moose Object.

This module will add "option" which act as "has" but support additional feature for getopt.

You will have "new_with_options" to instanciate new object for command line.
=cut

use strict;
use warnings;
use Carp;

# VERSION
my @OPTIONS_ATTRIBUTES
    = qw/format short repeatable negativable autosplit doc required/;

sub import {
    my ($class, @import) = @_;
    my %import_options = (protect_argv => 1, flavour => [], @import);
    
    my $target = caller;
    my $with = $target->can('with');
    my $around = $target->can('around');

    $with->('MooX::Options::Role');

    my $_options_meta = {};
    my $modifier_done;
    my $option = sub {
        my ( $name, %attributes ) = @_;
        for my $ban(qw/help option new_with_options parse_options options_usage _options_meta _options_params/) {
            croak "You cannot use an option with the name '$ban', it is implied by MooX::Options"
            if $name eq $ban;
        }
        $_options_meta->{$name}
            = { _validate_and_filter_options(%attributes) };
        $target->can('has')->( $name => _filter_attributes(%attributes) );
        unless ($modifier_done) {
            $around->(
                _options_meta => sub {
                    my ( $orig, $self ) = ( shift, shift );
                    return ( $self->$orig(@_), %$_options_meta );
                }
            );
            $around->(
                _options_params => sub {
                    my ( $orig, $self ) = ( shift, shift );
                    return ( $self->$orig(@_), %import_options );
                }
            );
            $modifier_done = 1;
        }
        return;
    };
    { no strict 'refs'; *{"${target}::option"} = $option; }

    return;
}

sub _filter_attributes {
    my %attributes = @_;
    my %filter_key = map { $_ => 1 } @OPTIONS_ATTRIBUTES;
    return map { ( $_ => $attributes{$_} ) }
        grep { !exists $filter_key{$_} } keys %attributes;
}

sub _validate_and_filter_options {
    my (%options) = @_;
    $options{doc} = $options{documentation} if !defined $options{doc};

    my %cmdline_options = map { ( $_ => $options{$_} ) }
        grep { exists $options{$_} } @OPTIONS_ATTRIBUTES;

    $cmdline_options{repeatable} = 1 if $cmdline_options{autosplit};
    $cmdline_options{format} .= "@" if $cmdline_options{repeatable} && defined $cmdline_options{format} && substr( $cmdline_options{format}, -1 ) ne '@';

    croak
        "Negativable params is not usable with non boolean value, don't pass format to use it !"
        if $cmdline_options{negativable} && defined $cmdline_options{format};

    return %cmdline_options;
}

1;

__END__

=head1 METHOD

=head2 IMPORT

The import method can take option :

=over

=item %options

=over

=item flavour

pass extra arguments for Getopt::Long::Descriptive.  it is usefull if you
want to configure Getopt::Long.

    use MooX::Options flavour => [qw( pass_through )];

Any flavour is pass to L<Getopt::Long> as a configuration, check the doc to see what is possible.

=item protect_argv

by default, argv is protected. if you want to do something else on it, use this option and it will change the real argv.

    use MooX::Options protect_argv => 0;

=back

=back

=head1 USAGE

First of all, I use L<Getopt::Long::Descriptive>. Everything will be pass to the programs, more specially the format.

    {
        package t;
        use Moo;
        use MooX::Options;

        option 'test' => (is => 'ro');

        1;
    }

    my $t = t->new_with_options(); #parse @ARGV
    my $o = t->new_with_options(test => 'override'); #parse ARGV and override any value with the params here

The keyword "option" work exactly like the keyword "has" and take extra argument of Getopt.

You can also use it over a Role.

    {
        package tRole;
        use Moo::Role;
        use MooX::Options;

        option 'test' => (is => 'ro');

        1;
    }

    {
        package t;
        use Moo;
        with 'tRole';
        1;
    }

    my $t = t->new_with_options(); #parse @ARGV
    my $o = t->new_with_options(test => 'override'); #parse ARGV and override any value with the params here

If you use Mo, you have a little bit more work to do. Because Mo lack of "with" and "around".


    {
        package tRole;
        use Moo::Role;
        use Mo;
        use MooX::Options;

        option 'test' => (is => 'ro');
        1;
    }
    {

        package t;
        use Mo;
        use Role::Tiny::With;
        with 'tRole';

        1;
    }
    my $t = t->new_with_options(); #parse @ARGV
    my $o = t->new_with_options(test => 'override'); #parse ARGV and override any value with the params here

It's a bit tricky but, hey, you are using Mo !

=head2 Keyword 'options_usage'

It display the usage message and return the exit code

    my $t = t->new_with_options();
    $t->options_usage(1, "str is not valid");

Params :

=over

=item $exit_code

Exit code after displaying the usage message

=item @messages

Additional message to display before the usage message

Ex: str is not valid

=back

=head2 Keyword 'new_with_options'

It will parse your command line params and your inline params, validate and call the 'new' method.

You can override the command line params :

Ex:

    local @ARGV=('--str=ko');
    t->new_with_options(str => 'ok');
    t->str; #ok

=head2 Keyword 'option' : EXTRA ARGS

=over

=item doc

Specified the documentation for the attribute

=item documentation

Specified the documentation for the attribute. It is usefull if you chain with other module like L<MooseX::App::Cmd> that use this attribute.

If doc attribute is defined, this one will be ignored.

=item required

Specified if the attribute is needed

=item format

Format of the params. It is the same as L<Getopt::Long::Descriptive>.

Example :

   i : integer
   i@: array of integer
   s : string
   s@: array of string
   f : float value

by default, it's a boolean value.

Take a look of available format with L<Getopt::Long::Descriptive>.

=item negativable

add the attribute "!" to the name. It will allow negative params.

Ex :

  test --quiet
  => quiet = 1

  test --quiet --no-quiet
  => quiet = 0

=item repeatable

add the attribute "@" to the name. It will allow repeatable params.

Ex :

  test --verbose
  => verbose = 1

  test --verbose --verbose
  => verbose = 2

it is advisable to use a "default" option on the attribute for repeatable
params so that they behave as arrays "out of the box" when used outside of
command line context.

Ex:
    {
        package t;
        use Moo;
        use MooX::Options;

        option foo => (is => 'rw', format => 's@', default => sub { [] });
        option bar => (is => 'rw', format => 'i@', default => sub { [] });

        1;
    }

    # this now works as expected and you will no longer see
    # "Can't use an undefined value as an ARRAY reference"
    my $t = t->new_with_options;
    push @{ $t->foo }, 'abc123';

    1;

=item autosplit

auto split args to generate multiple value. It implie "repeatable".
autosplit take the separator value, ex: ",".

Ex :

    {
        package t;
        use Moo;
        use MooX::Options;

        option test => (is => 'ro', format => 'i@', autosplit => ',');
        #same as : option test => (is => 'ro', format => 'i', autosplit => ',');
        1;
    }

    local @ARGV=('--test=1,2,3,4');
    my $t = t->new_with_options;
    t->test # [1,2,3,4]


I automatically take the quoted as a group separator value

    {
        package str;
        use Moo;
        use MooX::Options;
        option test => (is => 'ro', format => 's', repeatable => 1, autosplit => ',');
        1;
    }

    local @ARGV=('--test=a,b,"c,d",e');
    my $t = str->new_with_options;
    t->test # ['a','b','c,d','e']

=item short

give short name of an attribute.

Ex :

    {
        package t;
        use Moo;
        use MooX::Options;

        option 'verbose' => (is => 'ro', repeatable => 1, short => 'v');

        1;
    }
    local @ARGV=('-vvv');
    my $t = t->new_with_options;
    t->verbose # 3

=back

=head1 THANKS

=over

=item Matt S. Trout (mst) <mst@shadowcat.co.uk> : For his patience and advice.

=back

