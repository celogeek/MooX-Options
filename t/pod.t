#!perl

use t::Test;
use warnings FATAL => 'all';

unless ( $ENV{RELEASE_TESTING} ) {
    plan(
        skip_all => 'these tests are for release candidate testing' );
}

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::Requires { 'Test::Pod' => 1.46 };

all_pod_files_ok();

done_testing();
