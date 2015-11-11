package t::Test;
use strict;
use warnings;
use Test::More;
use Import::Into;
use POSIX qw/setlocale LC_ALL/;

sub import {
    $ENV{LC_ALL} = 'C';
    setlocale(LC_ALL, 'C');
    my $target = caller;
    strict->import::into($target);
    warnings->import::into($target);
    Test::More->import::into($target);
}

1;
