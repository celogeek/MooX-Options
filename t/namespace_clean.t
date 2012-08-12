use strict;
use warnings;
use Test::More;

eval q{

    package Foo;
    use Moo;
    use MooX::Options;
    use namespace::clean;

    # FIXME - Don't know why this with is needed?!?!
    with 'MooX::Options::Role';
    option foo => (is => 'ro', format => 's');
};

::ok !$@ or diag $@;
::ok Foo->new;

done_testing;

