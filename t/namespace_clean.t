use strict;
use warnings;
use Test::More;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

use_ok 'TestNamespaceClean';

ok TestNamespaceClean->new, 'TestNamespaceClean is a package';

{
    local @ARGV = ( '--foo', '12' );
    my $i = TestNamespaceClean->new_with_options;
    is $i->foo, 12, 'value save properly';
}

done_testing;

