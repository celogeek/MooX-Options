#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Carp;

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
    qw/help option new_with_options parse_options options_usage _options_data _options_config/
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

{
    eval <<EOF
    {
        package FailureRoleMyRole;
        use Moo::Role;
        use MooX::Options;
        option 't' => (is => 'rw');
        1;
    }
    {
        package FailureRole;
        use Moo;
        with 'FailureRoleMyRole';
        1;
    }
EOF
    ;
    like $@,
    qr/^Can't\sapply\sFailureRoleMyRole\sto\sFailureRole\s-\smissing\s_options_data,\s_options_config/x,
    "role could only be apply with a MooX::Options ready package"
}

done_testing;
