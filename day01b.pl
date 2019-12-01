#!/usr/bin/perl
#
# $Id: pl.template,v 1.2 2014/07/18 15:01:38 caran Exp $
#
use strict;
use warnings;

use Path::Tiny;

my $input_file = $ARGV[0] || 'input01.txt';

sub calc_fuel
 {
  my ($mass) = @_;
 
  my $total_fuel = 0;

  while ((my $fuel = (int( $mass / 3 ) - 2)) > 0) {
    $total_fuel += $fuel;
    $mass = $fuel;
   }

  return $total_fuel;
 }

my $total_fuel = 0;

for (path( $input_file )->lines_utf8( { chomp => 1 } )) {
  $total_fuel += calc_fuel( $_ );
 }

print "The total fuel is $total_fuel\n";
