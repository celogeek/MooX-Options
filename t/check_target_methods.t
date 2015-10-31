#!perl
use strict;
use warnings;
use Test::More;

{

    package t;
    use Moo;
    use MooX::Options;

    option 't' => ( is => 'ro' );

    1;
}

my $test = t->new_with_options;

my %ignore_methods;
@ignore_methods{
    qw/
        AUTOLOAD
        BEGIN
        BUILD
        BUILDARGS
        DEMOLISH
        DOES
        ISA
        __ANON__
        DESTROY
        /
} = ();

my @methods;
{
    no strict 'refs';
    @methods = sort { $a cmp $b }
        grep { !exists $ignore_methods{$_} } keys %{ ref($test) . "::" };
}

is_deeply(
    \@methods,
    [   qw/
            _options_config
            _options_data
            _options_prog_name
            _options_sub_commands
            after
            around
            before
            can
            does
            extends
            has
            new
            new_with_options
            option
            options_help
            options_man
            options_short_usage
            options_usage
            parse_options
            t
            with
            /
    ],
    'methods ok'
) or diag "Found : ", join( ', ', @methods );

done_testing;
