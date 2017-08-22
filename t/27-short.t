#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;

{

    package t;
    use Moo;
    use MooX::Options;

    option 'date_pattern' => (
        is      => 'rw',
        default => sub {'%Y-%m-%d %H:%M:%S %Z'},
        short   => 'dpat',
        format  => 's',
        doc     => 'Date pattern',
    );

    option dryrun => (
        is    => 'rw',
        short => 'd',
        doc   => 'Perform a dry run',
    );

    1;
}

my @messages;

trap { t->new_with_options( h => 1 ) };

ok !$trap->die,    'No die';
ok !$trap->stdout, 'No stdout';
ok $trap->stderr,   'stderr is set';
like $trap->stderr, qr/show a short help message/,
    'Program compiled OK. Short names are working';

done_testing;
