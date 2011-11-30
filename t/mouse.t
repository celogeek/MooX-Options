#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;

BEGIN {
	use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Mouse for this test' unless check_install(module => 'Mouse');
}

{
    package t;
    use Mouse;
    use MooX::Option filter => 'Mouse';

    option 'bool' => (is => 'ro' );
    option 'counter' => (is => 'ro', repeatable => 1);
    option 'empty' => (is => 'ro', negativable => 1);
    option 'split' => (is => 'ro', format => 'i@', autosplit => 1);

    1;
}

{
    package r;
    use Mouse;
    use MooX::Option filter => 'Mouse';
    
    option 'str_req' => (is => 'ro', format => 's', required => 1);
    
    1;
}

subtest "Mouse" => sub {
    note "Test Mouse";
    require $RealBin.'/base.st';
};

done_testing;
