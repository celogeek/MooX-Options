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
#      CREATED:  15/05/2012 15:17:46
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

{

    package V;
    use Data::Dumper;

    sub import {
        my $caller = caller;
        no strict "refs";
        *{"${caller}::option"} = sub {
            my $chain = "has";

            #this work :
            my $meth = eval "package $caller; sub {$chain(\@_)}";
            $meth->(@_);

            #this work also :
            my $meth = $caller->can($chain);
            goto &$meth;

            #this doesnt work :
            my $meth = $caller->can($chain);
            $meth->(@_);
        };
    }
    1;
}

{

    package T;
    use Mouse;

    BEGIN {
        V->import;
    }

    option 'bool' => ( is => 'rw' );

    __PACKAGE__->meta->make_immutable;
    1;
}

my $t = T->new;
$t->bool(1);
