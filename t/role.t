#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

{

    package myRole;
    use strict;
    use warnings;
    use Moo::Role;
    use MooX::Options;

    option 'multi' => ( is => 'rw', doc => 'multi threading mode' );
    1;
}

{

    package testRole;
    use Moo;
    with 'myRole';
    1;
}

{
    local @ARGV;
    @ARGV = ();
    my $opt = testRole->new_with_options;
    ok( !$opt->multi, 'multi not set' );
}
{
    local @ARGV;
    @ARGV = ('--multi');
    my $opt = testRole->new_with_options;
    ok( $opt->multi, 'multi set' );
    trap {
        $opt->options_usage;
    };
    ok( $trap->stdout =~ /\-\-multi\s+multi\sthreading\smode/x,
        "usage method is properly set" );
}

done_testing;
1;
