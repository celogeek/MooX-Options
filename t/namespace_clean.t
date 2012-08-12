use strict;
use warnings;
use Test::More;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";

use_ok 'Foo';

::ok Foo->new;

{
    local @ARGV = ('--foo', '12');
    my $i = Foo->new_with_options;
    is $i->foo, 12;
}

done_testing;

