package MooX::Option;
# ABSTRACT: add option keywords to your Moo object
=head1 MooX::Option

Use Getopt::Long::Descritive to provide command line option for your Mo/Moo/Mouse/Moose Object.
    
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
            format => 's',
        );

        option "arr" => (
            is => 'ro',
            doc => "My array",
            format => 'i@',
            autosplit => ',',
        )
        1;
    }

    my $opt = t->new_with_options();

=cut

use strict;
use warnings;
# VERSION
use Carp;
use Data::Dumper;
use Getopt::Long::Descriptive;
use Regexp::Common;
use Data::Record;

my %_default_options = (
	'creation_method' => 'new',
	'chain_method' => 'has',
    'option_method_name' => 'option',
    'creation_method_name' => 'new_with_options',
);

my %_filter_chain = (
    'Mo' => undef,
    'Moo' => undef,
    'Mouse' => [qw/format short repeatable negativable autosplit/],
    'Moose' => [qw/format short repeatable negativable autosplit/],
);

=head1 METHOD

=head2 IMPORT

The import method can take option :

=over

=item %options

creation_method : call this method after parsing option, default : new

chain_method : call this method to create the attribute, default : has

option_method_name : name of keyword you want to use to create your option, default : option

creation_method_name : name of new method to handle option, default : new_with_options

filter : 

by default all params is passed to the chain_method, 
but you can have warning with some method, 
you can use the filter I have set to remove some params to the chain method

available filter : Mo, Moo, Mouse, Moose

=item Example

    use MooX::Option creation_method => 'my_new_method', chain_method => 'my_chain_method';

Filter for specific object model : (Mo and Moo don t need any filter, you can obmit the params)
    {package pmo; use Mo; use MooX::Option filter => 'Mo'};
    {package pmoo; use Moo; use MooX::Option filter => 'Moo'};
    {package pmouse; use Mouse; use MooX::Option filter => 'Mouse'};
    {package pmoose; use Moose; use MooX::Option filter => 'Moose'};

=back
	
=cut
sub import {
	my (undef, @_params) = @_;
	my (%options) = (%_default_options, @_params);
    my $caller = caller;

    my @_options = ('USAGE: %c %o');
    my @_attributes = ();
    my @_required_attributes = ();
    my %_autosplit_attributes = ();
    
    my @_filter_chain_key;
    @_filter_chain_key = @{$_filter_chain{$options{filter}}} if $options{filter} && defined $_filter_chain{$options{filter}};

    {
        #keyword option
        my $chain_method = $caller->can($options{chain_method});
        croak "No method ",$options{chain_method}, " found" unless $chain_method;
        croak "No method name for option" unless $options{option_method_name};
        croak "Method ",$options{option_method_name}, " already defined !" if $caller->can($options{option_method_name});
        
        no strict 'refs';
        *{"${caller}::$options{option_method_name}"} = sub {
            my ($name, %options) = @_;
            croak "Negativable params is not usable with non boolean value, don't pass format to use it !" if $options{negativable} && $options{format};

            #fix missing option, autosplit implie repeatable
            $options{repeatable} = 1 if $options{autosplit};

            #help is use for help message only
            if ($name ne 'help') {
            	my $name_long_and_short = join "|", grep { defined $_ } $name, $options{short}; 
                #fix format for negativable or add + if it is a boolean
                if ($options{repeatable}) {
                    if ($options{format}) {
                        $options{format} .= "@" unless substr($options{format}, -1) eq '@';
                    } else {
                        $name_long_and_short .= "+";
                    }
                }
                #negativable for boolean value
                $name_long_and_short .= "!" if $options{negativable};

                #format the name
                my $name_format = join "=", grep { defined $_ } $name_long_and_short, $options{format};

                push @_options, [ $name_format, $options{doc} // "no doc for $name" ];              # prepare option for getopt
                push @_attributes, $name;                                                           # save the attribute for later use
                push @_required_attributes, $name if $options{required};                            # save the required attribute
                $_autosplit_attributes{$name} = Data::Record->new( {split => $options{autosplit}, unless => $RE{quoted}} ) if $options{autosplit};    # save autosplit value
            }

            #remove bad key for passing to chain_method(has), avoid warnings with Moo/Moose
            #by defaut, keep all key
            if (@_filter_chain_key) {
	            delete $options{$_} for @_filter_chain_key;
                @_ = ($name, %options);
	        }

            #chain to chain_method (has)
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
            my ($self, %params) = @_;

            #if autosplit attributes is present, search and replace in ARGV with full version
            #ex --test=1,2,3 become --test=1 --test=2 --test=3
            if (%_autosplit_attributes) {
	            my @_ARGV;
                #parse all argv
                for my $arg (@ARGV) {
                    my ($arg_name, $arg_values) = split(/=/, $arg, 2);
                    $arg_name =~ s/^--?//;
                    if (my $rec = $_autosplit_attributes{$arg_name}) {
                        foreach my $record($rec->records($arg_values)) {
                            #remove the quoted if exist to chain
                            $record =~ s/^['"]|['"]$//g;
                            push @_ARGV, "--$arg_name=$record";
                        }
                    } else {
                        push @_ARGV, $arg;
                    }
                }
                @ARGV = @_ARGV;
	        }

            #call describe_options
            my ($opt, $usage) = describe_options(@_options,["help|h", "show this help message"]);
            print($usage->text), exit if $opt->help;

            #replace command line attribute in params if params not defined
            my @_existing_attributes = grep { $opt->can($_) && defined $opt->$_ && !exists $params{$_}} @_attributes;
            @params{@_existing_attributes} = @$opt{@_existing_attributes};

            #check required params, if anything missing, display help
            my @_missing_params = grep { !defined $params{$_} } @_required_attributes;            
            print(join("\n",(map { "$_ is missing"} @_missing_params), $usage->text)), exit(1) if @_missing_params;
            
            #call creation_method
            @_ = ($self, %params);
	        goto &$creation_method;
        };
    }
}


1;

__END__

=head1 USAGE

First of all, I use L<Getopt::Long::Descriptive>. Everything will be pass to the programs, more specially the format.


    package t;
    use Moo;
    use MooX::Option;
    
    option 'test' => (is => 'ro');
    
    1;

    my $t = t->new_with_options(); #parse @ARGV
    my $o = t->new_with_options(test => 'override'); #parse ARGV and override any value with the params here
    
The keyword "option" work exactly like the keyword "has" and take extra argument of Getopt.

=head2 EXTRA ARGS

=over

=item doc

Specified the documentation for the attribute

=item required

Specified if the attribute is needed

=item format

Format of the params. It is the same as L<Getopt::Long::Descriptive>.

Example :
   
   i : integer
   i@: array of integer
   s : string
   s@: array of string
   f : float value
   
by default, it's a boolean value.

Take a look of available format with L<Getopt::Long::Descriptive>.

=item negativable

add the attribute "!" to the name. It will allow negative params.

Ex :

  test --quiet
  => quiet = 1

  test --quiet --no-quiet
  => quiet = 0

=item repeatable

add the attribute "@" to the name. It will allow repeatable params.

Ex :

  test --verbose
  => verbose = 1

  test --verbose --verbose
  => verbose = 2

=item autosplit

auto split args to generate multiple value. You need to specified the format with "@" to make it work.

Ex :

    package t;
    use Moo;
    use MooX::Option;
    
    option test => (is => 'ro', format => 'i@', autosplit => 1);
    1;
    
    @ARGV=('--test=1,2,3,4');
    my $t = t->new_with_options;
    t->test # [1,2,3,4]

=item short

give short name of an attribute.

Ex :

    package t;
    use Moo;
    use MooX::Option;
    
    option 'verbose' => (is => 'ro', repeatable => 1, short => 'v');
    
    1;
    @ARGV=('-vvv');
    my $t = t->new_with_options;
    t->verbose # 3

=back 

=head1 THANKS

=over

=item Matt S. Trout (mst) <mst@shadowcat.co.uk>

For his patience and advice.

=back
    
=head1 BUGS

Any bugs or evolution can be submit here :

L<Github|https://github.com/geistteufel/MooX-Option>
