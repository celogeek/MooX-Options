package MooX::Options::Descriptive;

# ABSTRACT: This method extend Getopt::Long::Descriptive to change the usage method

use strict;
use warnings;
# VERSION

use Getopt::Long 2.38;
use Getopt::Long::Descriptive 0.091;
use MooX::Options::Descriptive::Usage;
use parent 'Getopt::Long::Descriptive';
sub usage_class { return 'MooX::Options::Descriptive::Usage' }

1;