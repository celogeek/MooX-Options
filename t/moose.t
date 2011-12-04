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
    plan skip_all => 'Need Moose for this test' unless check_install(module => 'Moose');
}

{
    package t;
    use Moose;
    use MooX::Option filter => 'Moose';

    option 'bool' => (is => 'ro' );
    option 'counter' => (is => 'ro', repeatable => 1);
    option 'empty' => (is => 'ro', negativable => 1);
    option 'split' => (is => 'ro', format => 'i@', autosplit => ',');

    1;
}

{
    package r;
    use Moose;
    use MooX::Option filter => 'Moose';
    
    option 'str_req' => (is => 'ro', format => 's', required => 1);
    
    1;
}

{ 
    package sp_str;
    use Moose;
    use MooX::Option filter => 'Moose';

    option 'split_str' => (is => 'ro', format => 's', autosplit => ",");

    1;
}

{
    package d;
    use Moose;
    use MooX::Option;
    option 'should_die_ok' => (is => 'ro', trigger => sub { die "ok"});
    1;
}

subtest "Moose" => sub {
    note "Test Moose";
    require $RealBin.'/base.st';
};

done_testing;
