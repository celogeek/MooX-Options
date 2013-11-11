#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Capture::Tiny qw/capture_stdout/;

BEGIN {
    eval 'use MooX::Cmd 0.007';
    if ($@) {
        plan skip_all => 'Need MooX::Cmd (0.007) for this test';
        exit 0;
    }
}

use t::lib::MooXCmdTest;

trap {
    local @ARGV = ('-h');
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'base command help ok';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: test1, test3\E}, 'sub base command help ok';

my $pod_help = do {
    local @ARGV = ();
    my $m = t::lib::MooXCmdTest->new;
    my %cmdline = $m->parse_options(man => 1);
    $cmdline{man}->option_pod($m);
};

like $pod_help, qr{\=head1 DESCRIPTION\s+\QThis is a test sub command\E}, 'pod description ok';
like $pod_help, qr{\=head1 AUTHORS\s+\=over\s+\Q=item B<Celogeek <me\E\@\Qcelogeek.com>>\E}, 'pod author ok';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_cmd();
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 [-h]\E}, 'subcommand 1 help ok';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: test2\E}, 'sub subcommand 1 help ok';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => []);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no subcommand pass';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => [123]);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no ref params';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => [{}]);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'bad ref';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => [bless {}, 'MooX::Cmd']);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'bad ref';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => [t::lib::MooXCmdTest->new]);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no command_name filled';

trap {
    local @ARGV = ('test1', '-h');
    t::lib::MooXCmdTest->new_with_options(command_chain => [t::lib::MooXCmdTest->new(command_name => 'mySub')], command_commands => {a => 1, b => 2});
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t mySub [-h]\E}, 'subcommand with mySub name';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: a, b\E}, 'sub subcommand with mySub name';

trap {
    local @ARGV = ('test1', 'test2', '-h');
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 test2 [-h]\E}, 'subcommand 2 ok';

done_testing;
