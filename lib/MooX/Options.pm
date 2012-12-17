package MooX::Options;

# ABSTRACT: add option keywords to your object (Mo/Moo/Moose)

=head1 MooX::Options

Use L<Getopt::Long::Descritive> to provide command line option for your Mo/Moo/Moose Object.

This module will add "option" which act as "has" but support additional feature for getopt.

You will have "new_with_options" to instanciate new object for command line.
=cut

use strict;
use warnings;
use Carp;

# VERSION
my @OPTIONS_ATTRIBUTES
    = qw/format short repeatable negativable autosplit doc order/;

sub import {
    my ( undef, @import ) = @_;
    my $options_config
        = { protect_argv => 1, flavour => [], skip_options => [], @import };

    my $target = caller;
    my $with   = $target->can('with');
    my $around = $target->can('around');
    my $has    = $target->can('has');


    my @target_isa;
    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    if (@target_isa) {
        #don't add this to a role
        #ISA of a role is always empty !
        ## no critic qw/ProhibitStringyEval/
        use warnings FATAL => 'redefine';
        eval '{
        package '.$target.';

            sub _options_data {
                my ( $class, @meta ) = @_;
                return $class->maybe::next::method(@meta);
            }

            sub _options_config {
                my ( $class, @params ) = @_;
                return $class->maybe::next::method(@params);
            }

        1;
        }';
        use warnings FATAL => qw/void/;

        croak $@ if $@;

        $around->(
            _options_config => sub {
                my ( $orig, $self ) = ( shift, shift );
                return $self->$orig(@_), %$options_config;
            }
        );

        ## use critic
    }

    my $options_data = {};
    my $apply_modifiers = sub {
        return if $target->can('new_with_options');
        $with->('MooX::Options::Role');

        $around->(
            _options_data => sub {
                my ( $orig, $self ) = ( shift, shift );
                return ( $self->$orig(@_), %$options_data );
            }
        );
    };

    my $option = sub {
        my ( $name, %attributes ) = @_;
        for my $ban (
            qw/help option new_with_options parse_options options_usage _options_data _options_config/
            )
        {
            croak
                "You cannot use an option with the name '$ban', it is implied by MooX::Options"
                if $name eq $ban;
        }

        $has->( $name => _filter_attributes(%attributes) );

        $options_data->{$name}
            = { _validate_and_filter_options(%attributes) };

        $apply_modifiers->();
        return;
    };

    if ( my $info = $Role::Tiny::INFO{$target} ) {
        $info->{not_methods}{$option} = $option;
    }

    { no strict 'refs'; *{"${target}::option"} = $option; }

    $apply_modifiers->();

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
    $options{order} = 0 if !defined $options{order};

    my %cmdline_options = map { ( $_ => $options{$_} ) }
        grep { exists $options{$_} } @OPTIONS_ATTRIBUTES, 'required';

    $cmdline_options{repeatable} = 1 if $cmdline_options{autosplit};
    $cmdline_options{format} .= "@"
        if $cmdline_options{repeatable}
        && defined $cmdline_options{format}
        && substr( $cmdline_options{format}, -1 ) ne '@';

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

=item skip_options

you can skip some option to remove the possibility to the terminal. in that case, the 'option' keyword will just works like an 'has'.

    use MooX::Options skip_options => [qw/multi/];

If you have multiple tools that use the same Role to generate params, you can skip one and force his value. In my example, it could be a multithread option that you want to disabling in some case.

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
        use MooX::Options; #you have to add this, or the role will not find the necessary methods
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

=item order

Specified the order of the attribute.

=back

=head1 namespace::clean

To use namespace::clean you need to add 2 methods as an exception. It is use by MooX::Options when you run the new_with_options methods.

    {
        package t;
        use Moo;
        use MooX::Options;
        use namespace::clean -except => [qw/_options_data _options_config/];
        option 'v' => (is => 'rw');
        1;
    }
    my $r = t->new_with_options;

=head1 no more Mouse support

If you are using Mouse, I'm sorry to say than the rewrite of this module has make it just incompatible. Mouse is not design to by compatible with anything else than Mouse itself. I could just suggest to use Moo instead, which is a great and compatible replacement.

=head1 More examples

L<http://perltalks.celogeek.com/slides/2012/08/moox-options-slide3d.html>

=head1 THANKS

=over

=item Matt S. Trout (mst) <mst@shadowcat.co.uk> : For his patience and advice.

=item Tomas Doran (t0m) <bobtfish@bobtfish.net> : To help me release the new version, and using it :)

=item Torsten Raudssus (Getty) : to use it a lot in L<DuckDuckGo|http://duckduckgo.com> (go to see L<MooX> module also)

=back

