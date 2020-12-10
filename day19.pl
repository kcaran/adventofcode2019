#!/usr/bin/env perl
#
# Size of map - 48 wide (including \n) x 65  = 3120
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use IntCode;

my $program = IntCode->new( 'input19.txt' );

my $count = 0;
my $debug = 0;

for (my $y = 0; $y < 50; $y++) {
  printf "%03d ", $y if ($debug);
  for (my $x = 0; $x < 50; $x++) {
     my $output = $program->init->run( $x, $y )->[0];
     $count++ if ($output);
     print( $output ? '#' : '.' ) if ($debug);
    }
   print "\n" if ($debug);
  }

print "The number of points affected are $count\n";

exit;
