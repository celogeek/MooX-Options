#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;

{

    package myRole;
    use strict;
    use warnings;
    use Moo::Role;
    use MooX::Options t => 1;

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

    package testSkipOpt;
    use Moo;
    use MooX::Options skip_options => [qw/multi/], u => 2;
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
{
    local $TODO = "Role not fully functional ...";
    local @ARGV;
    @ARGV = ('--multi');
    my $opt = testSkipOpt->new_with_options;
    ok( !$opt->multi, 'multi not set' );
    trap {
        $opt->options_usage;
    };
    ok( $trap->stdout !~ /\-\-multi\s+multi\sthreading\smode/x,
        "usage method is properly set" );
}

done_testing;
1;
