#!/usr/bin/perl
#
# $Id: pl.template,v 1.2 2014/07/18 15:01:38 caran Exp $
#
use strict;
use warnings;

use Data::Printer;
use Path::Tiny;

my $PI = 3.14159265358979;

{ package Asteroid;

  sub new {
    my ($class, $x, $y) = @_;

    my $self = {
      x => $x,
      y => $y,
      theta => {},
    };

    bless $self, $class;

    return $self;
  }
}

{ package Grid;

  sub blast_asteroids {
    my ($self, $station, $max) = @_;

    my $count = 0;
    while (1) {
      for my $theta (sort { $a <=> $b } keys %{ $station->{ theta } }) {
        my $target = shift @{ $station->{ theta }{ $theta } };
        next unless $target;
        $count++;
print "The $count target is at ($target->{ x }, $target->{ y })\n";
        return $target if ($count == $max);
       }
     }

    return;
   }

  sub calc_polar {
    my ($self, $x, $y) = @_;

    my $r = sqrt( $x ** 2 + $y ** 2 );
    my $theta = atan2( $y, $x );

    # Part 2 - Convert theta to degrees starting from 0 (N)
    return( $r, 0 ) if ($y >= 0 && $x == 0);
    return( $r, 180 ) if ($y < 0 && $x == 0);

    $theta = ($theta / $PI) * 180;
    $theta = (450 - $theta);
    $theta -= 360 if ($theta > 360);
   
    return( $r, $theta );
   }

  sub find_max {
    my ($self) = @_;
    my $max = 0;
    my $max_rock;
    for my $rock (@{ $self->{ rocks } }) {
      my $count = scalar keys $rock->{ theta };
      if ($count > $max) {
        $max = $count;
        $max_rock = $rock;
       }
     }

    print "Best is $max_rock->{ x }, $max_rock->{ y } with $max other asteroids detected.\n";

    return $max_rock;
   }

  sub find_targets {
    my ($self) = @_;

    for my $rock (@{ $self->{ rocks } }) {
      for my $target (@{ $self->{ rocks } }) {
        next if ($target == $rock);
        # NOTE: Y-coord is opposite polarity
        my ($r, $theta) = $self->calc_polar( $target->{ x } - $rock->{ x }, $rock->{ y } - $target->{ y } );
        push @{ $rock->{ theta }{ $theta } }, { r => $r, x => $target->{ x }, y => $target->{ y } };
        $rock->{ theta }{ $theta } = [ sort { $a->{ r } <=> $b->{ r } } @{ $rock->{ theta }{ $theta } } ];
       }
     }
   }

  sub new {
    my ($class, $input_file) = @_;

    my $self = {};

    my $row = 0;
    for my $line (Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
      my $pos = 0;
      while ((my $col = index( $line, '#', $pos )) >= 0) {
        push @{ $self->{ rocks } }, Asteroid->new( $col, $row );
        $pos = $col + 1;
       }
      $row++;
     }

    $self->{ dim } = $row;

    bless $self, $class;

    return $self;
  }
}

my $input_file = $ARGV[0] || 'input10.txt';

my $grid = Grid->new( $input_file );
$grid->find_targets();
my $station = $grid->find_max();
my $last_target = $grid->blast_asteroids( $station, $ARGV[1] || 200 );

print "The final target has a value of ", $last_target->{ x } * 100 + $last_target->{ y }, "\n";

exit;
