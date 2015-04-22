#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;

{
	package t;
	use Moo;
	use MooX::Options;

	option 'visible_option' => (is => 'ro', doc => 'visible');
	option 'hidden_option_by_doc' => (is => 'ro', format => 's', doc => 'hidden');
	option 'hidden_option' => (is => 'ro', format => 's', hidden => 1, doc => 'not visible');
	1;
}

trap { local @ARGV = qw(--help); t->new_with_options };

unlike $trap->stdout, qr/hidden_option_by_doc:/, 'hidden by doc';
unlike $trap->stdout, qr/hidden_option:/, 'hidden by option';
like $trap->stdout, qr/visible_option:/, 'visible option';

{
	local @ARGV = qw(--hidden_option_by_doc=test1 --hidden_option=test2);
	my $o = t->new_with_options;

	is $o->hidden_option_by_doc, 'test1', 'hidden by doc exists';
	is $o->hidden_option, 'test2', 'hidden by option exists';
}

done_testing;
