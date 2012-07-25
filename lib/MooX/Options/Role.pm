package MooX::Options::Role;
# ABSTRACT: create role with option
use strict;
use warnings;
# VERSION
use Carp;

=head1 SYNOPSIS

    use strict;
    use warnings;
    use v5.16;
    {package myRole;
     use MooX::Options::Role;
     option 'multi' => (is => 'rw', doc => 'multi threaded mode');
     1;
    }
    {package myOpt;
    use Moo;
    use MooX::Options;
    myRole->import;
    1;
    }

    my $opt = myOpt->new_with_options();
    say "Multi : ",$opt->multi;


You take a look at t/role.t for more example.

=cut

my %Options;
=method import
Import method "option" that will be transmit to L<MooX::Options> when the role is used.

If you decide to change the "option" key in the import of L<MooX::Options>, L<MooX::Options::Role> will know and call the appropriate method.
=cut
sub import {
    my $option_role_meth = sub {
        my ($name, %options) = @_;
        $Options{$name} = \%options;
    };

    my $import_meth = sub {
        my $caller = caller;
        ## no critic qw(ProhibitPackageVars)
        my $option_meth_name = $caller::MooX_Options_Option_Name;
        ## use critic
        croak "MooX::Options should be import before using this role" unless defined $option_meth_name;
        my $option_meth = $caller->can($option_meth_name);
        for my $name(keys %Options) {
            my %option = %{$Options{$name}};
            $option_meth->($name, %option);
        }
    };

    my $caller = caller;
    {
        ## no critic qw(ProhibitNoStrict)
        no strict qw/refs/;
        *{"${caller}::option"} = $option_role_meth;
        *{"${caller}::import"} = $import_meth;
        ## use critic
    }
    return;
}

1;
