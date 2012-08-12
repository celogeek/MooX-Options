#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Moo for this test'
        unless check_install( module => 'Moo' );
}

eval <<EOF
    package FailureNegativableWithFormat;
    use Moo;
    use MooX::Options;

    option fail => (
        is => 'rw',
        negativable => 1,
        format => 'i',
    );

    1;
EOF
    ;
like $@,
    qr/^Negativable\sparams\sis\snot\susable\swith\snon\sboolean\svalue,\sdon't\spass\sformat\sto\suse\sit\s\!/x,
    "negativable and format are incompatible";

for my $ban (
    qw/help option new_with_options parse_options options_usage _options_meta _options_params/
    )
{
    eval <<EOF
    package FailureHelp$ban;
    use Moo;
    use MooX::Options;

    option $ban => (
        is => 'rw',
    );
EOF
        ;
    like $@,
        qr/^You\scannot\suse\san\soption\swith\sthe\sname\s'$ban',\sit\sis\simplied\sby\sMooX::Options/x,
        "$ban method can't be defined";
}

done_testing;
