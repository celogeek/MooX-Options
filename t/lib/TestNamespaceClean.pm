package TestNamespaceClean;
use Moo;
use MooX::Options;
use namespace::clean -except => [qw/_options_data _options_config __ __n __p/];

option foo => ( is => 'ro', format => 's' );

1;
