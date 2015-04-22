#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

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
    use MooX::Options;
    with 'myRole';
    1;
}

{

    package testRole2;
    use Moo;
    use MooX::Options skip_options => undef;
    with 'myRole';
    1;
}

{

    package testSkipOpt;
    use Moo;
    use MooX::Options skip_options => [qw/multi/],
      flavour                      => [qw( pass_through )];
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
    like( $trap->stdout, qr/\-\-multi:\n\s+multi\sthreading\smode/x,
        "usage method is properly set"
    );
}
{
    local @ARGV;
    @ARGV = ();
    my $opt = testRole2->new_with_options;
    ok( !$opt->multi, 'multi not set' );
}
{
    local @ARGV;
    @ARGV = ('--multi');
    my $opt = testRole2->new_with_options;
    ok( $opt->multi, 'multi set' );
    trap {
        $opt->options_usage;
    };
    like( $trap->stdout, qr/\-\-multi:\n\s+multi\sthreading\smode/x,
        "usage method is properly set"
    );
}
{
    local @ARGV;
    @ARGV = ('--multi');
    my $opt = testSkipOpt->new_with_options;
    ok( !$opt->multi, 'multi not set' );
    trap {
        $opt->options_usage;
    };
    ok( $trap->stdout !~ /\-\-multi\s+multi\sthreading\smode/x,
        "usage method is properly set"
    );
}

done_testing;
1;
