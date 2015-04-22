#!perl
use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

use POSIX qw(setlocale LC_ALL);

BEGIN {
  setlocale LC_ALL, 'C';
}

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t;
    use Moo;
    use MooX::Options;

    option 't' => (
        is            => 'ro',
        documentation => 'this is a test',
    );

    around options_usage => sub {
        my ($orig, $self, $code, @message) = @_;
        $code = 0 if !defined $code;
        print "This is a pre message\n";
        $self->$orig(-1, @message);
        print "\nThis is a post message\n";
        exit($code) if $code >= 0;
    };

    1;
}


trap { t->new_with_options(help => 1) };
my @messages = split(/\n/, $trap->stdout);
is $messages[0], 'This is a pre message', 'Pre message ok';
like $messages[1], qr{^USAGE}, 'Usage ok';
is $messages[-1], 'This is a post message', 'Post message ok';

done_testing;
