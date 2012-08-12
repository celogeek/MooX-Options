package Foo;
use Moo;
use MooX::Options;
use namespace::clean;

option foo => (is => 'ro', format => 's');

1;

