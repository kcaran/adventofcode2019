#!/usr/bin/env perl
#
# Tests for generic IntCode module
#
use strict;
use warnings;
use utf8;

use Test::More;

ok( `perl day19.pl` =~ /231/, 'Day 19 part a' );
ok( `perl day19b.pl 3` =~ /210017/, 'Day 19 part b' );
ok( `perl day21.pl < data21a.txt` =~ /19348840/, 'Day 21 part a' );

done_testing();
