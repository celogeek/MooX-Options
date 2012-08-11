#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

BEGIN {
    use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Moose for this test'
        unless check_install( module => 'Moose' );
}

{

    package t;
    use Moose;
    use MooX::Options;

    option 'bool'    => ( is => 'ro' );
    option 'counter' => ( is => 'ro', repeatable => 1 );
    option 'empty'   => ( is => 'ro', negativable => 1 );
    option 'split'   => ( is => 'ro', format => 'i@', autosplit => ',' );

    1;
}

{

    package r;
    use Moose;
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}

{

    package sp_str;
    use Moose;
    use MooX::Options;

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );

    1;
}

{

    package d;
    use Moose;
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', trigger => sub { die "this will die ok" } );
    1;
}

{

    package multi_req;
    use Moose;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}

{

    package t_doc;
    use Moose;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}

subtest "Moose" => sub {
    note "Test Moose";
    require $RealBin . '/base.st';
};

done_testing;
