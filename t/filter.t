#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
	use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Moo for this test' unless check_install(module => 'Moo');
}

{
    package TestFilter;
    use Moo;
    use Test::More;

    sub test_filter {
        my ($name, %options) = @_;
        is_deeply(\%options, {
            is => 'rw',
        }, 'test with Moo filter');
        has($name,%options);
    }

    use MooX::Options option_chain_method => 'test_filter';

    option 't' => (
        is => 'rw',
        format => 'i',
        short => 'u',
        repeatable => 1,
        autosplit => 1,
        doc => 't is t',
    );

    1;

}

TestFilter->new_with_options;

{
    package TestNoFilter;
    use Moo;
    use Test::More;

    sub test_filter {
        my ($name, %options) = @_;
        is_deeply(\%options, {
            is => 'rw',
            format => 'i',
            short => 'u',
            repeatable => 1,
            autosplit => 1,
            doc => 't is t',
        }, 'test with no Moo filter');
        has($name, %options);
    }

    use MooX::Options option_chain_method => 'test_filter', nofilter => 1;

    option 't' => (
        is => 'rw',
        format => 'i',
        short => 'u',
        repeatable => 1,
        autosplit => 1,
        doc => 't is t',
    );

}

TestNoFilter->new_with_options;
done_testing;
