#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Trap;

{
    package t1;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
        order         => 1,
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
        order         => 2,
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
        order         => 3,
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
        order         => 4,
    );

    1;
}

{
    package t2;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
    );

    1;
}

{
    package t3;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
        order         => 1,
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
        order         => 2,
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
    );

    1;
}

{
    my $opt = t1->new_with_options;
    trap { $opt->options_usage };
    ok $trap->stdout =~ /first.+second.+third.+fourth/gms, 'order work w/ order attribute';
}

{
    my $opt = t2->new_with_options;
    trap { $opt->options_usage };
    ok $trap->stdout =~ /first.+fourth.+second.+third/gms, 'order work w/o order attribute';
}

{
    my $opt = t3->new_with_options;
    trap { $opt->options_usage };
    ok $trap->stdout =~ /fourth.+third.+first.+second/gms, 'order work w/ mixed mode';
}

done_testing;
