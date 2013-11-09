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
	t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 [-h]\E}, 'subcommand 1 ok';

trap {
	local @ARGV = ('test1', 'test2', '-h');
	t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 test2 [-h]\E}, 'subcommand 2 ok';

done_testing;
