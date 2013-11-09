#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

BEGIN {
	eval 'use MooX::Cmd 0.006001';
	if ($@) {
		plan skip_all => 'Need MooX::Cmd (0.006001) for this test';
		exit 0;
	}
}

use t::lib::MooXCmdTest;

trap {
	local @ARGV = ('-h');
	t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'base command help ok';

trap {
	local @ARGV = ('test1', '-h');
	t::lib::MooXCmdTest->new_with_cmd();
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 [-h]\E}, 'subcommand 1 ok';

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
	t::lib::MooXCmdTest->new_with_options(command_chain => [t::lib::MooXCmdTest->new(command_name => 'mySub')]);
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t mySub [-h]\E}, 'subcommand with mySub name';

trap {
	local @ARGV = ('test1', 'test2', '-h');
	t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 test2 [-h]\E}, 'subcommand 2 ok';

done_testing;
