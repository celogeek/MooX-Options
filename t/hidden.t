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
	option 'hidden_option_by_doc' => (is => 'ro', doc => 'hidden');
	option 'hidden_option' => (is => 'ro', hidden => 1, doc => 'not visible');
	1;
}

trap { local @ARGV = qw(--help); t->new_with_options };

unlike $trap->stdout, qr/hidden_option_by_doc:/, 'hidden by doc';
unlike $trap->stdout, qr/hidden_option:/, 'hidden by option';
like $trap->stdout, qr/visible_option:/, 'visible option';

done_testing;
