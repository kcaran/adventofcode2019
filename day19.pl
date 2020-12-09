#!/usr/bin/env perl
#
# Size of map - 48 wide (including \n) x 65  = 3120
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use IntCode;

{ package Grid;

  sub display {
    my ($self) = @_;

    for my $y (0 .. @{ $self->{ grid } } - 1) {
      for my $x (0 .. @{ $self->{ grid }[$y] } - 1) {
        print $self->{ grid }[$y][$x];
        if ($self->{ grid }[$y][$x] eq '#' && $x > 0 && $y > 0
          && $self->{ grid }[$y-1][$x] eq '#'
          && ($self->{ grid }[$y+1][$x] || '') eq '#'
          && $self->{ grid }[$y][$x-1] eq '#'
          && ($self->{ grid }[$y][$x+1] || '') eq '#') {
          $self->{ align } += $y * $x;
         }      
       }
      print "\n";
     }

    return $self;
   }

  sub new {
    my ($class, $input) = @_;

    my $self = {
      grid => [],
      align => 0,
    };

   my ($x, $y) = (0, 0);
   for my $char (@{ $input }) {
     if ($char == 10) {
       $x = 0;
       $y++;
       next;
      }

     $self->{ grid }[$y][$x] = chr( $char );
     $x++;
    }

   bless $self, $class;

   return $self;
  }
}

use Data::Dumper;

my $program = IntCode->new( 'input19.txt' );

my $count = 0;

for (my $x = 0; $x < 50; $x++) {
  for (my $y = 0; $y < 50; $y++) {
     my $output = $program->init->run( $x, $y );
print "$x, $y, $output->[0]\n";
     $count++ if ($output->[0]);
    }
  }

print "The number of points affected are $count\n";

exit;
