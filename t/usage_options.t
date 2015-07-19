#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;

{
    package t;
	use strict;
	use warnings;
    use Moo;
    use MooX::Options 
        usage_string => 'usage: myprogram <hi> %o',
        usage_top    => ['USAGE_TOP'],
        usage_bottom => ['USAGE_BOTTOM'],
        man_option   => 0,
        usage_option => 0;

    option 'hero' => (
        is     => 'ro',
        doc    => 'this is mandatory',
		format => 's@',
    );

    1;
}

{
    local @ARGV = (qw/--bad-option/);
    trap { my $opt = t->new_with_options(); };
	like 
        $trap->stderr, 
        qr/usage: myprogram <hi> \[-h\] \[long options/,  
        'stderr has correct usage';
	unlike $trap->stderr, qr/--usage/,  'no --usage option';
	unlike $trap->stderr, qr/--man/,    'no --man option';

    my @lines = split "\n", $trap->stderr;
	like $lines[3], qr/USAGE_TOP/, 'found usage_top';
	like $lines[-1], qr/USAGE_BOTTOM/, 'found usage_bottom';
}

done_testing;


