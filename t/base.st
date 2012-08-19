
my @params = qw/bool counter empty/;
subtest "no args" => sub {
    note "no args";
    local @ARGV = ();
    my $t = t->new_with_options();
    ok( $t->can($_), "$_ defined" ) for @params;
    is( $t->$_, undef, "$_ values is undef" ) for @params;
    is( $t->has_default, 'foo', 'Default works correctly' );
    done_testing();
};

subtest "args value" => sub {
    note "args value with repeatable";
    local @ARGV
        = ( '--bool', '--counter', '--counter', '--counter', '--empty' );
    my $t = t->new_with_options();
    note "bool ",    $t->bool;
    note "counter ", $t->counter;
    note "empty ",   $t->empty;
    ok( $t->$_, "$_ values is defined" ) for @params;
    is( $t->bool,    1, "bool is well defined" );
    is( $t->counter, 3, "counter is well defined" );
    is( $t->empty,   1, "empty is well defined" );
    done_testing();
};

subtest "negativable" => sub {
    note "negativable";
    local @ARGV = ( '--empty', '--no-empty' );
    my $t = t->new_with_options();
    is( $t->empty, 0, "empty is well defined" );
    done_testing();
};

subtest "split" => sub {
    note "split";

    {
        local @ARGV = ('--split=1');
        my $t = t->new_with_options();
        is_deeply( $t->split, [1], "split one arg" );
    }
    {
        local @ARGV = ( '--split=1', '--split=2' );
        my $t = t->new_with_options();
        is_deeply( $t->split, [ 1, 2 ], "split two arg" );
    }
    {
        local @ARGV = ('--split=1,2');
        my $t = t->new_with_options();
        is_deeply( $t->split, [ 1, 2 ], "split one arg autosplit" );
    }
    {
        local @ARGV = ( '--split=1', '--split=2', '--split=3,4' );
        my $t = t->new_with_options();
        is_deeply(
            $t->split,
            [ 1, 2, 3, 4 ],
            "split three arg with autosplit"
        );
    }
    {
        local @ARGV = ( '--split', '1', '--split', '2', '--split', '3,4' );
        my $t = t->new_with_options();
        is_deeply(
            $t->split,
            [ 1, 2, 3, 4 ],
            "split three arg with autosplit and space"
        );
    }
    done_testing();
};

subtest "test required" => sub {
    note "test required";

    {
        local @ARGV = ();
        my @r = trap { r->new_with_options };
        is( $trap->exit, 1, "missing args, exit 1" );
        ok( $trap->stdout =~ /^str_req is missing/, "str_reg is missing" );
    }
    {
        local @ARGV = ('--str_req=ok');
        my $t = r->new_with_options;
        is( $t->str_req, 'ok', 'str req is ok' );
    }
    {
        local @ARGV = ();
        my @r = trap { multi_req->new_with_options };
        is( $trap->exit, 1, "missing args exit 1" );
        my @missing = $trap->stdout =~ /(multi_\d is missing)\n/g;
        is( scalar @missing, 3, "multi is missing" );
    }
    done_testing();
};

subtest "test help" => sub {
    note "test help";
    {
        local @ARGV = ('--help');
        my @r = trap { r->new_with_options };
        is( $trap->exit, 0, "help, exit 0" );
        ok( $trap->stdout !~ /^str_req is missing/, "str_reg is missing" );
    }
    done_testing();
};

subtest "value override" => sub {
    note "value override";
    {
        local @ARGV = ();
        my $t = r->new_with_options( str_req => "ok" );
        is( $t->str_req, 'ok', 'str req is ok' );
    }
    {
        local @ARGV = ('--str_req=ko');
        my $t = r->new_with_options( str_req => "ok" );
        is( $t->str_req, 'ok', 'str req is override with ok' );
    }
    done_testing();
};

subtest "split_complexe_str" => sub {
    note "split on complexe str";
    {
        local @ARGV = ("--split_str=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ('--split_str=a,"b,c",d');
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [ 'a', 'b,c', 'd' ], 'str req is ok' );
    }
    done_testing();
};

subtest "should_die_ok" => sub {
    note "Test chain method";
    try {
        d->new_with_options( should_die_ok => 1 );
    }
    catch {
        ok( /this\s\will\sdie\sok/, 'should die ok' );
    };
};

subtest "test usage" => sub {
    note "test usage method";
    my $s     = sp_str->new_with_options();
    my @r = trap { $s->options_usage( 127, 'usage work', 'usage really work' ) };
    is( $trap->exit, 127, 'exit code is correct' );
    ok( $trap->stdout =~ /usage work/, 'custom message is present' );
    ok( $trap->stdout =~ /usage really work/,
        'custom message is really present'
    );
    ok( $trap->stdout =~ /help.*show this help message/, 'help is present' );
    ok( $trap->stdout =~ /split_str.*no doc for split_str/,
        'attr no doc is present' );
};

subtest "doc usage" => sub {
    note "doc usage";
    my $s     = t_doc->new_with_options();
    my @r = trap { $s->options_usage(127) };
    is( $trap->exit, 127, 'exit code is correct' );
    ok( $trap->stdout =~ /t.*this is a test/, 'doc on attribute' );
};

subtest "test short" => sub {
    note "test short";
    my $s     = t_short->new_with_options();
    trap { $s->options_usage };
    ok ($trap->stdout =~ /\-v \-\-verbose/, 'short doc ok');
};

subtest "test skip_options" => sub {
    note "test skip_options";
    my $s = t_skipopt->new_with_options();
    trap { $s->options_usage() };
    ok ($trap->stdout !~ /\-\-multi/, 'multi is no more an option');
};

1;
