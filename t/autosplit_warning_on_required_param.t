#!perl
use t::Test;
use Test::Trap;

{

    package t;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option 'treq' => (
        is            => 'ro',
        documentation => 'this is mandatory',
        format        => 's@',
        required      => 1,
        autosplit     => ",",
    );

    1;
}

{
    local @ARGV = ('--treq');
    trap { my $opt = t->new_with_options(); };
    like $trap->stderr,   qr/^Option treq requires an argument/, 'stdout ok';
    unlike $trap->stderr, qr/Use of uninitialized/, 'stderr ok';
}

done_testing;

