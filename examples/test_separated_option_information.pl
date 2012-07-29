#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  a.pl
#
#        USAGE:  ./a.pl  
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
#      CREATED:  28.07.2012 20:11:24
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Carp;

{package myOpt;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option t => (is => 'rw', doc => 'test');
    1;
}
{package myOpt2;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option x => (is => 'ro', doc => 'test2');
    option y => (is => 'ro', doc => 'test3');
    option z => (is => 'ro', doc => 'test4');
    1
}

my $a = myOpt->new_with_options;
my $b = myOpt2->new_with_options;
my $c = myOpt->new_with_options;

