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
    plan skip_all => 'Need Mo for this test'
      unless check_install( module => 'Mo' );
}

{

    package tRole;
    use Moo::Role;
    use Mo 'default';
    use MooX::Options;

    option 'bool'    => ( is => 'ro' );
    option 'counter' => ( is => 'ro', repeatable => 1 );
    option 'empty'   => ( is => 'ro', negativable => 1 );
    option 'split'   => ( is => 'ro', format => 'i@', autosplit => ',' );
    option 'has_default' => ( is => 'ro', default => sub {'foo'} );

    1;
}
{

    package t;
    use Mo;
    use Role::Tiny::With;
    with 'tRole';

    1;
}

{

    package rRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}
{

    package r;
    use Mo;
    use Role::Tiny::With;
    with 'rRole';

    1;
}

{

    package sp_strRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str1' =>
      ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str2' =>
      ( is => 'ro', format => 's', autosplit => "," );

    1;
}
{

    package sp_str;
    use Mo;
    use Role::Tiny::With;
    with 'sp_strRole';

    1;
}

{

    package sp_str_shortRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'split_str' =>
      ( is => 'ro', format => 's', autosplit => ",", short => 'z' );

    1;
}
{

    package sp_str_short;
    use Mo;
    use Role::Tiny::With;
    with 'sp_str_shortRole';

    1;
}


{

    package dRole;
    use Moo::Role;
    use Mo 'coerce';
    use MooX::Options;
    option 'should_die_ok' =>
      ( is => 'ro', coerce => sub { die "this will die ok" } );
    1;
}
{

    package d;
    use Mo 'coerce';
    use Role::Tiny::With;
    with 'dRole';
    1;
}

{

    package multi_reqRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}
{

    package multi_req;
    use Mo;
    use Role::Tiny::With;
    with 'multi_reqRole';
    1;
}

{

    package t_docRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}
{

    package t_doc;
    use Mo;
    use Role::Tiny::With;
    with 't_docRole';
    1;
}

{

    package t_shortRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;
    option 'verbose' => ( is => 'ro', short => 'v' );
    1;
}

{

    package t_short;
    use Mo;
    use Role::Tiny::With;
    with 't_shortRole';
    1;
}

{

    package t_skipoptRole;
    use Moo::Role;
    use Mo;
    use MooX::Options skip_options => [qw/multi/];

    option 'multi' => ( is => 'ro' );
    1;
}
{

    package t_skipopt;
    use Mo;
    use Role::Tiny::With;
    with 't_skipoptRole';
    1;
}

{

    package t_prefer_cliRole;
    use Moo::Role;
    use Mo;
    use MooX::Options prefer_commandline => 1;

    option 't' => ( is => 'ro', format => 's' );
    1;
}
{

    package t_prefer_cli;
    use Mo;
    use Role::Tiny::With;
    with 't_prefer_cliRole';
    1;
}

{

    package t_dashRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'start_date' => ( is => 'ro', format => 's', short => 's' );
    1;
}
{

    package t_dash;
    use Mo;
    use Role::Tiny::With;
    with 't_dashRole';
    1;
}

{

    package t_jsonRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 't' => ( is => 'ro', json => 1 );
    1;

}

{

    package t_json;
    use Mo;
    use Role::Tiny::With;
    with 't_jsonRole';
    1;
}

subtest "Mo" => sub {
    note "Test Mo";
    require $RealBin . '/base.st';
};


done_testing;
