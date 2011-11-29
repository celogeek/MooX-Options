package MooX::Option;
# ABSTRACT: add option keywords to your Moo object
=head1 MooX::Option

Use Getopt::Long::Descritive to provide command line option for your Moo Object.
    
This module will add "option" which act as "has" but support additional feature for getopt.

You will have "new_with_options" to instanciate new object for command line.
=cut

=head1 SYNOPSIS

    {
        package t; 
        use Moo; use MooX::Option;

        option "str" => (
            is => 'ro',
            required => '1',
            doc => "My String Option",
            format => 'Bool',
        );
        1;
    }

    my $opt = t->new_with_options();

=cut

use strict;
use warnings;
use Carp;
# VERSION

sub import {
    my $caller = caller;
    my $caller_new = $caller->can('new');
    my $caller_has = $caller->can('has');
    croak "No method new for $caller" unless $caller_new;
    croak "No method has for $caller" unless $caller_has;

    no strict 'refs';
    *{"${caller}::option"} = sub {
        #todo capture option;
        goto &$caller_has;
    };

    *{"${caller}::new_with_options"} = sub {
        #todo capture option;
        goto &$caller_new;
    };
}


1;
