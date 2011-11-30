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
use Data::Dumper;
# VERSION

my %_default_options = (
	'creation_method' => 'new',
	'chain_method' => 'has',
    'option_method_name' => 'option',
    'creation_method_name' => 'new_with_options',
);

=head1 METHOD

=head2 IMPORT

The import method take option :

=over

=item %options

creation_method : call this method after parsing option, default : new

chain_method : call this method to create the attribute, default : has

option_method_name : name of keyword you want to use to create your option, default : option

creation_method_name : name of new method to handle option, default : new_with_options

=back
	
=cut
sub import {
	my $class = shift;
	my (%options) = (%_default_options, @_);
    my $caller = caller;

    {
        #keyword option
        my $chain_method = $caller->can($options{chain_method});
        croak "No method ",$options{chain_method}, " found" unless $chain_method;
        croak "No method name for option" unless $options{option_method_name};
        croak "Method ",$options{option_method_name}, " already defined !" if $caller->can($options{option_method_name});
        
        no strict 'refs';
        *{"${caller}::$options{option_method_name}"} = sub {
            #todo capture option;
            goto &$chain_method;
        };
    }

    {
    	#keyword new_with_options
        my $creation_method = $caller->can($options{creation_method});
        croak "No method ",$options{creation_method}, " found" unless $creation_method;
    	croak "No method name for creation" unless $options{creation_method_name};
        croak "Method ",$options{creation_method_name}, " already defined !" if $caller->can($options{creation_method_name});
    	
	    no strict 'refs';
	    *{"${caller}::$options{creation_method_name}"} = sub {
	        #todo capture option;
	        goto &$creation_method;
        };
    }
}


1;
