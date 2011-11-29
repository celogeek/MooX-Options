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
# VERSION

sub import {
    my $caller = caller;
    my $current = __PACKAGE__;
    no strict 'refs';
    for my $method(qw/option new_with_options/) {
        *{"${caller}::${method}"} = *{"${current}::${method}"};
    }
}

sub option {
    my ($name, %options) = @_;

    {
        #call has method
        no strict 'refs';
        my $caller = caller;
        my $sub = *{"${caller}::has"}{CODE};
        goto &$sub;
    }
}

sub new_with_options {
    my ($class, %options) = @_;
}

1;
