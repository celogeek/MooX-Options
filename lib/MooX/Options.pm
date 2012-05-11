package MooX::Options;
# ABSTRACT: add option keywords to your Moo object
=head1 MooX::Options

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
use 5.8.9;

my %DEFAULT_OPTIONS = (
	'creation_chain_method' => 'new',
    'creation_method_name' => 'new_with_options',
	'option_chain_method' => 'has',
    'option_method_name' => 'option',
    'flavour' => [],
);

my @FILTER = qw/format short repeatable negativable autosplit doc/;

sub import {
	my (undef, %import_params) = @_;
	my (%import_options) = (%DEFAULT_OPTIONS, %import_params);
    my $caller = caller;
    
    #check options and definition
    while(my ($key, $method) = each %import_options) {
    	croak "missing option $key, check doc to define one" unless $method;
        croak "method $method is not defined, check doc to use another name" if $key =~ /_chain_method$/ && !$caller->can($method);
        croak "method $method already defined, check doc to use another name" if $key =~ /_method_name$/ && $caller->can($method);
    }

    my @Options = ('USAGE: %c %o');
    my @Attributes = ();
    my @Required_Attributes = ();
    my %Autosplit_Attributes = ();
    my $Usage="";
    
    {
        #keyword option
        no strict 'refs';
        *{"${caller}::$import_options{option_method_name}"} = sub {
            my ($name, %options) = @_;
            croak "Negativable params is not usable with non boolean value, don't pass format to use it !" if $options{negativable} && $options{format};
            croak "Can't use option with help, it is implied by MooX::Options" if $name eq 'help';
            croak "Can't use option with ".$import_options{option_method_name}."_usage, it is implied by MooX::Options" if $name eq $import_options{option_method_name}."_usage";


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

            #doc
            my $doc = defined $options{doc} ? $options{doc} : "no doc for $name";

            push @Options, [ $name_format, $doc ];                   # prepare option for getopt
            push @Attributes, $name;                                 # save the attribute for later use
            push @Required_Attributes, $name if $options{required};  # save the required attribute
            $Autosplit_Attributes{$name} = Data::Record->new( {split => $options{autosplit}, unless => $RE{quoted}} ) if $options{autosplit};    # save autosplit value

            #remove bad key for passing to chain_method(has), avoid warnings with Moo/Moose
            #by defaut, keep all key
            unless ($import_options{nofilter}) {
	            delete $options{$_} for @FILTER;
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
            print(join("\n",@messages, $Usage)), exit($code);
        }
    }

    {
    	#keyword new_with_options
	    no strict 'refs';
	    *{"${caller}::$import_options{creation_method_name}"} = sub {
            my ($self, %params) = @_;

            #ensure all method will be call properly
            for my $attr(@Attributes) {
                croak "attribute ".$attr." isn't defined. You have something wrong in your option_chain_method '".$import_options{option_chain_method}."'." unless $self->can($attr);
            }


            #if autosplit attributes is present, search and replace in ARGV with full version
            #ex --test=1,2,3 become --test=1 --test=2 --test=3
            if (%Autosplit_Attributes) {
	            my @new_argv;
                #parse all argv
                for my $arg (@ARGV) {
                    my ($arg_name, $arg_values) = split(/=/, $arg, 2);
                    $arg_name =~ s/^--?//;
                    if (my $rec = $Autosplit_Attributes{$arg_name}) {
                        foreach my $record($rec->records($arg_values)) {
                            #remove the quoted if exist to chain
                            $record =~ s/^['"]|['"]$//g;
                            push @new_argv, "--$arg_name=$record";
                        }
                    } else {
                        push @new_argv, $arg;
                    }
                }
                @ARGV = @new_argv;
	        }

            #call describe_options
            my $usage_method = $self->can("$import_options{option_method_name}_usage");
            my ($opt, $usage) = describe_options(@Options,["help|h", "show this help message"], { getopt_conf => $import_options{flavour} });
            $Usage = $usage->text;
            $usage_method->(0) if $opt->help;

            #replace command line attribute in params if params not defined
            my @existing_attributes = grep { my $attr = $_; my $attr_val = $opt->$attr; defined $attr_val && !exists $params{$attr}} @Attributes;
            @params{@existing_attributes} = @$opt{@existing_attributes};

            #check required params, if anything missing, display help
            my @missing_params = grep { !defined $params{$_} } @Required_Attributes;            
            $usage_method->(1, map { "$_ is missing"} @missing_params) if @missing_params;
            
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

don't filter extra params for MooX::Options before calling chain_method 

it is usefull if you want to use this params for something else

=item flavour

pass extra arguments for Getopt::Long::Descriptive.  it is usefull if you
want to configure Getopt::Long.

    use MooX::Options flavour => [qw( pass_through )];

Any flavour is pass to L<Getopt::Long> as a configuration, check the doc to see what is possible.

=back

=back

=head1 USAGE

First of all, I use L<Getopt::Long::Descriptive>. Everything will be pass to the programs, more specially the format.

    package t;
    use Moo;
    use MooX::Options;
    
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

it is advisable to use a "default" option on the attribute for repeatable
params so that they behave as arrays "out of the box" when used outside of
command line context.

Ex:
    package t;
    use Moo;
    use MooX::Options;

    option foo => (is => 'rw', format => 's@', default => sub { [] });
    option bar => (is => 'rw', format => 'i@', default => sub { [] });

    # this now works as expected and you will no longer see
    # "Can't use an undefined value as an ARRAY reference"
    my $t = t->new;
    push @{ $t->foo }, 'abc123';

    1;

=item autosplit

auto split args to generate multiple value. It implie "repeatable".
autosplit take the separator value, ex: ",".

Ex :

    package t;
    use Moo;
    use MooX::Options;
    
    option test => (is => 'ro', format => 'i@', autosplit => ',');
    #same as : option test => (is => 'ro', format => 'i', autosplit => ',');
    1;
    
    @ARGV=('--test=1,2,3,4');
    my $t = t->new_with_options;
    t->test # [1,2,3,4]


I automatically take the quoted as a group separator value

    package str;
    use Moo;
    use MooX::Options;
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
    use MooX::Options;
    
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

L<Github|https://github.com/geistteufel/MooX-Options>
