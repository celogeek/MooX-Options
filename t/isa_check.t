#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;

use POSIX qw(setlocale LC_ALL);

BEGIN {
  setlocale LC_ALL, 'C';
}

{
    package t;
	use strict;
	use warnings;
    use Moo;
    use MooX::Options;

    option 'hero' => (
        is     => 'ro',
        doc    => 'this is mandatory',
		format => 's@',
        isa    => sub { die "boop\n" },
    );

    1;
}

{
	local @ARGV = (qw/--hero batman/);
    trap { my $opt = t->new_with_options(); };
	like $trap->stderr, qr/^boop/,  'stdout ok';
	like $trap->stderr, qr/USAGE/, 'stderr ok';
}

done_testing;


