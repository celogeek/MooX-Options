#!/usr/bin/env perl

{
    package t;
    use Moo;
    use MooX::Option;

    option 'str' => (is => 'ro', required => 1);
    #has 'str' => (is => 'ro');

    1;
}

use strict;
use warnings;
use Test::More;
use Carp;
my $t = t->new(str => 'toto');#_with_options();
ok($t->can('str'),"str exists");
is($t->str, "toto", "str is properly sets");
done_testing;
