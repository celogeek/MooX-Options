#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

{

    package t;
    use Moo;
    use MooX::Options;

    option 'bool'    => ( is => 'ro' );
    option 'counter' => ( is => 'ro', repeatable => 1 );
    option 'empty'   => ( is => 'ro', negativable => 1 );
    option 'split'   => ( is => 'ro', format => 'i@', autosplit => ',' );
    option 'has_default' => ( is => 'ro', default => sub {'foo'} );

    1;
}

{

    package r;
    use Moo;
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}

{

    package sp_str;
    use Moo;
    use MooX::Options;

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );

    1;
}

{

    package d;
    use Moo;
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', isa => sub { die "this will die ok" } );
    1;
}

{

    package multi_req;
    use Moo;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}

{

    package t_doc;
    use Moo;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}

{

    package t_short;
    use Moo;
    use MooX::Options;
    option 'verbose' => ( is => 'ro', short => 'v' );
    1;
}

{

    package t_skipopt;
    use Moo;
    use MooX::Options skip_options => [qw/multi/];

    option 'multi' => ( is => 'ro' );
    1;
}

{

    package t_dash;
    use Moo;
    use MooX::Options;

    option 'start_date' => ( is => 'ro', dash => 1, format => 's', short => 's' );
    1;
}

subtest "Moo" => sub {
    note "Test Moo";
    require $RealBin . '/base.st';
};

done_testing;
