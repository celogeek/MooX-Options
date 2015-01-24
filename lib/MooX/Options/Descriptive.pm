package MooX::Options::Descriptive;

# ABSTRACT: This method extend Getopt::Long::Descriptive to change the usage method

=head1 DESCRIPTION

This class will override the usage_class method, to customize the output of the help

=cut

use strict;
use warnings;
# VERSION

use Getopt::Long 2.38;
use Getopt::Long::Descriptive 0.099;
use MooX::Options::Descriptive::Usage;
use parent 'Getopt::Long::Descriptive';

=method usage_class

Method to use for the descriptive build

=cut
sub usage_class { return 'MooX::Options::Descriptive::Usage' }

1;
