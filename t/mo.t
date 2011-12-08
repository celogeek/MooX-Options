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
    plan skip_all => 'Need Mo for this test' unless check_install(module => 'Mo');
}

{
    package t;
    use Mo;
    use MooX::Options filter => 'Mo';

    option 'bool' => (is => 'ro' );
    option 'counter' => (is => 'ro', repeatable => 1);
    option 'empty' => (is => 'ro', negativable => 1);
    option 'split' => (is => 'ro', format => 'i@', autosplit => ',');

    1;
}

{
    package r;
    use Mo;
    use MooX::Options filter => 'Mo';
    
    option 'str_req' => (is => 'ro', format => 's', required => 1);
    
    1;
}

{ 
    package sp_str;
    use Mo;
    use MooX::Options;

    option 'split_str' => (is => 'ro', format => 's', autosplit => ",");

    1;
}

{
    package d;
    use Mo 'coerce';
    use MooX::Options;
    option 'should_die_ok' => (is => 'ro', coerce => sub { die "ok"});
    1;
}

{
    package multi_req;
    use Mo;
    use MooX::Options;
    option 'multi_1' => (is => 'ro', required => 1);
    option 'multi_2' => (is => 'ro', required => 1);
    option 'multi_3' => (is => 'ro', required => 1);
}


subtest "Mo" => sub {
    note "Test Mo";
    require $RealBin.'/base.st';
};



done_testing;
