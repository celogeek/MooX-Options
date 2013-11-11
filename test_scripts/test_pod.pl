#!/usr/bin/perl 
#===============================================================================
#
#         FILE: test.pl
#
#        USAGE: ./test.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10.11.2013 17:07:33
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use lib 'lib';

{
	package myOpt;
	use Moo;
	use MooX::Options
	description => "Hello world !",
	authors => ['Celogeek <me@celogeek.com>', 'Test <me@test.com>'],
	synopsis => 
	"This is a test. An it works !";

	option 'test' => (is => 'ro', format => 's', doc => 'pouet', long_doc => 'pouet pouet');
	option 'test2' => (is => 'ro', autosplit => ',', format => 's@', doc => 'pouet', long_doc => 'pouet pouet');

	1;
}

my $o = myOpt->new_with_options;
