#!/usr/bin/env perl
#
# $Id: $
#
use strict;
use warnings;
use utf8;

my $lower = $ARGV[0] || 206938;
my $upper = $ARGV[1] || 679128;

my $count = 0;
my $part_b = 1;

sub is_valid {
  my $passwd = shift;

  my (@dupes) = ($passwd =~ /(\d)\1/g);
  return 0 unless @dupes;

  if ($part_b) {
    my $exactly_two = 0;
    for my $digit (@dupes) {
      $exactly_two ||= ($passwd =~ /(?<!$digit)$digit{2}(?!$digit)/);
     }
    return 0 unless ($exactly_two);
   }

  my $val = -1;
  for my $digit (split( '', $passwd )) {
    return 0 if ($digit < $val);
    $val = $digit;
   }

  return 1;
 }

for (my $i = $lower; $i <= $upper; $i++) {
  $count++ if (is_valid( $i ));
 }

print "The number of valid passwords in the $lower-$upper range is $count\n";
