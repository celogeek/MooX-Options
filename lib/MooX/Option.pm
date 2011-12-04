package MooX::Option;
# ABSTRACT: add option keywords to your Moo object
=head1 MooX::Option

Use Getopt::Long::Descritive to provide command line option for your Mo/Moo/Mouse/Moose Object.
    
This module will add "option" which act as "has" but support additional feature for getopt.

You will have "new_with_options" to instanciate new object for command line.
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
	'creation_chain_method' => 'new',
    'creation_method_name' => 'new_with_options',
	'option_chain_method' => 'has',
    'option_method_name' => 'option',
);

my @_filter = qw/format short repeatable negativable autosplit doc/;

sub import {
	my (undef, @_params) = @_;
	my (%import_options) = (%_default_options, @_params);
    my $caller = caller;
    
    #check options and definition
    while(my ($key, $method) = each %_default_options) {
    	croak "missing option $key, check doc to define one" unless $method;
        croak "method $method is not defined, check doc to use another name" if $key =~ /_chain_method$/ && !$caller->can($method);
        croak "method $method already defined, check doc to use another name" if $key =~ /_method_name$/ && $caller->can($method);
    }


    my @_options = ('USAGE: %c %o');
    my @_attributes = ();
    my @_required_attributes = ();
    my %_autosplit_attributes = ();
    my $_usage="";
    
    {
        #keyword option
        no strict 'refs';
        *{"${caller}::$import_options{option_method_name}"} = sub {
            my ($name, %options) = @_;
            croak "Negativable params is not usable with non boolean value, don't pass format to use it !" if $options{negativable} && $options{format};
            croak "Can't use option with help, it is implied by MooX::Option" if $name eq 'help';

            #fix missing option, autosplit implie repeatable
            $options{repeatable} = 1 if $options{autosplit};

            #help is use for help message only
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

            #remove bad key for passing to chain_method(has), avoid warnings with Moo/Moose
            #by defaut, keep all key
            unless ($options{nofilter}) {
	            delete $options{$_} for @_filter;
                @_ = ($name, %options);
	        }

            #chain to chain_method (has)
            my $chain_method = $caller->can($import_options{option_chain_method});
            goto &$chain_method;
        };
    }

    {
        #keyword option
        no strict 'refs';
        *{"${caller}::$import_options{option_method_name}_usage"} = sub {
            my ($code, @messages) = @_;
            print(join("\n",@messages, $_usage)), exit($code);
        }
    }

    {
    	#keyword new_with_options
	    no strict 'refs';
	    *{"${caller}::$import_options{creation_method_name}"} = sub {
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
            my $usage_method = $self->can("$import_options{option_method_name}_usage");
            my ($opt, $usage) = describe_options(@_options,["help|h", "show this help message"]);
            $_usage = $usage->text;
            $usage_method->(0) if $opt->help;

            #replace command line attribute in params if params not defined
            my @_existing_attributes = grep { $opt->can($_) && defined $opt->$_ && !exists $params{$_}} @_attributes;
            @params{@_existing_attributes} = @$opt{@_existing_attributes};

            #check required params, if anything missing, display help
            my @_missing_params = grep { !defined $params{$_} } @_required_attributes;            
            $usage_method->(1, map { "$_ is missing"} @_missing_params) if @_missing_params;
            
            #call creation_method
            @_ = ($self, %params);

            my $creation_method = $caller->can($import_options{creation_chain_method});
	        goto &$creation_method;
        };
    }
}


1;

__END__

=head1 METHOD

=head2 IMPORT

The import method can take option :

=over

=item %options

=over

=item creation_chain_method

call this method after parsing option, default : new

=item creation_method_name

name of new method to handle option, default : new_with_options

=item option_chain_method

call this method to create the attribute, default : has

=item option_method_name

name of keyword you want to use to create your option, default : option

it will create ${option_method_name}_usage too, ex: option_usage($exit_code, @{additional messages})

=item nofilter

don't filter extra params for MooX::Option before calling chain_method 

it is usefull if you want to use this params for something else

=back

=back

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

=head2 Keyword 'option_usage'

It display the usage message and return the exit code

    option_usage(1, "str is not valid");

Params :

=over

=item $exit_code

Exit code after displaying the usage message

=item @messages

Additional message to display before the usage message

Ex: str is not valid

=back

=head2 Keyword 'new_with_options'

It will parse your command line params and your inline params, validate and call the 'new' method.

You can override the command line params :

Ex:

    @ARGV=('--str=ko');
    t->new_with_options(str => 'ok');
    t->str; #ok

=head2 Keyword 'option' : EXTRA ARGS

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

auto split args to generate multiple value. It implie "repeatable".
autosplit take the separator value, ex: ",".

Ex :

    package t;
    use Moo;
    use MooX::Option;
    
    option test => (is => 'ro', format => 'i@', autosplit => ',');
    #same as : option test => (is => 'ro', format => 'i', autosplit => ',');
    1;
    
    @ARGV=('--test=1,2,3,4');
    my $t = t->new_with_options;
    t->test # [1,2,3,4]


I automatically take the quoted as a group separator value

    package str;
    use Moo;
    use MooX::Option;
    option test => (is => 'ro', format => 's', repeatable => 1, autosplit => ',');
    1;
    
    @ARGV=('--test=a,b,"c,d",e');
    my $t = str->new_with_options;
    t->test # ['a','b','c,d','e']

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

=item Matt S. Trout (mst) <mst@shadowcat.co.uk> : For his patience and advice.

=back
    
=head1 BUGS

Any bugs or evolution can be submit here :

L<Github|https://github.com/geistteufel/MooX-Option>
