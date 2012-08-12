#!perl
use strict;
use warnings;

use Test::More;    # last test to print

{

    package r1;
    use Moo::Role;
    use MooX::Options;

    option 'r1' => ( is => 'ro' );
    1;
}
{

    package r2;
    use Moo::Role;
    use MooX::Options;

    option 'r2' => ( is => 'ro' );
    1;
}
{

    package t;
    use Moo;
    use MooX::Options;
    with 'r1', 'r2';
    1
}

local @ARGV = ('--r1','--r2');
my $r = t->new_with_options;
ok($r->r1, 'r1 set');
ok($r->r2, 'r2 set');

done_testing;
