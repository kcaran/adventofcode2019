#!/usr/bin/perl
#
# $Id: pl.template,v 1.2 2014/07/18 15:01:38 caran Exp $
#
use strict;
use warnings;

use Data::Printer;
use Path::Tiny;

{ package Grid;

  sub move_wire {
    my $self = shift;
    my $path = shift;

    $self->{ num_wires }++;
    my $x = 0;
    my $y = 0;
    my $steps = 0;
    for my $move (split /,/, $path) {
      my ($dir, $len) = ($move =~ /^(\w)(\d+)/);
      for (my $i = 0; $i < $len; $i++) {
        $steps++;
        $x++ if ($dir eq 'R');
        $x-- if ($dir eq 'L');
        $y-- if ($dir eq 'U');
        $y++ if ($dir eq 'D');
        $self->test_intersect( $x, $y, $steps );
       }
     }

    return $self;
   }

  sub test_intersect {
   my ($self, $x, $y, $steps) = @_;
   my $point = "$x,$y";
   my $wire = $self->{ num_wires } - 1;

   # Ignore if we've already been here
   return if ($self->{ grid }[$wire]{ $point });

   $self->{ grid }[$wire]{ $point } = $steps;

   if ($wire == 1) {
     if ($self->{ grid }[0]{ $point }) {
       # Part a - check for an intersection
       my $dist = abs( $x ) + abs( $y );
       if ($self->{ intersect } < 0 || $self->{ intersect } > $dist) {
         $self->{ intersect } = $dist;
        }

       # Part b - check number of steps
       my $steps = $self->{ grid }[0]{ $point } + $self->{ grid }[1]{ $point };
       if ($self->{ steps } < 0 || $self->{ steps } > $steps) {
         $self->{ steps } = $steps;
        }
      }
    }

   return $self;
  }

  sub new {
    my $class = shift;
    my $self = { 
		grid => [],
		intersect => -1,
        num_wires => 0,
        steps => -1,
		};

    bless $self, $class;

    return $self;
  }
}

my $grid = Grid->new();

my $input_file = $ARGV[0] || 'input03.txt';

for (path( $input_file )->lines_utf8( { chomp => 1 } )) {
  $grid->move_wire( $_ );
 }

print "The nearest intersection is $grid->{ intersect }\n";
print "The minimum number of steps to an intersection is $grid->{ steps }\n";
