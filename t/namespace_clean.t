use strict;
use warnings;
use Test::More;

eval q{
    package Foo;
    use Moo;
    use MooX::Options;
    use namespace::clean;

    option foo => (is => 'ro', format => 's');

    1;
};

ok Foo->new, 'Foo is a package';

{
    local @ARGV = ( '--foo', '12' );
    my $i = Foo->new_with_options;
    is $i->foo, 12, 'value save properly';
}

done_testing;

