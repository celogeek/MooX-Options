#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  b.pl
#
#        USAGE:  ./b.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  29.07.2012 19:00:15
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use v5.16;


BEGIN
{package mySuperOpt;
    use Moose;
    use MooX::Options;

    option 't1' => ( is => 'rw', documentation => 't1' );
    1;
}
;
{package myOpt;
    use Moose;
    use MooX::Options;
    extends 'mySuperOpt';

    option 't2' => ( 'is' => 'rw', documentation => 't2' );
    1;
};

#mySuperOpt->new_with_options;
#myOpt->new_with_options;
my $a = myOpt->new_with_options(t1 => 1, t2 => 2);
say $a->t1;
say $a->t2;

