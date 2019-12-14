#!/usr/bin/env perl
#
use strict;
use warnings;

use Path::Tiny;

{ package Moon;

  sub energy {
    my ($self) = @_;

    return (abs( $self->{ x } ) + abs( $self->{ y } ) + abs( $self->{ z } ))
		* (abs( $self->{ vx } ) + abs( $self->{ vy } ) + abs( $self->{ vz } ));
   }

  sub gravity {
    my ($self, $moon) = @_;

    if ($moon->{ x } > $self->{ x }) {
      $self->{ vx }++;
      $moon->{ vx }--;
     }
    elsif ($moon->{ x } < $self->{ x }) {
      $self->{ vx }--;
      $moon->{ vx }++;
     }

    if ($moon->{ y } > $self->{ y }) {
      $self->{ vy }++;
      $moon->{ vy }--;
     }
    elsif ($moon->{ y } < $self->{ y }) {
      $self->{ vy }--;
      $moon->{ vy }++;
     }

    if ($moon->{ z } > $self->{ z }) {
      $self->{ vz }++;
      $moon->{ vz }--;
     }
    elsif ($moon->{ z } < $self->{ z }) {
      $self->{ vz }--;
      $moon->{ vz }++;
     }

    return $self;
   }

  sub move {
    my ($self) = @_;

    $self->{ x } += $self->{ vx };
    $self->{ y } += $self->{ vy };
    $self->{ z } += $self->{ vz };

    return $self;
   }

  sub print {
    my ($self) = @_;

    printf "pos=<x=%2d, y=%2d, z=%2d>, vel=<x=%d, y=%2d, z=%2d>\n",
		@{ $self }{ qw( x y z vx vy vz ) };

    return;
   }

  sub new {
    my ($class, $input) = @_;
    my ($x, $y, $z) = ($input =~ /<x=([0-9-]+),\s*y=([0-9-]+),\s*z=([0-9-]+)/);

    my $self = {
      x => $x,
      y => $y,
      z => $z,
      vx => 0,
      vy => 0,
      vz => 0,
    };

    bless $self, $class;

    return $self;
   }
}

sub energy {
  my ($moons) = @_;
  my $energy = 0;

  for my $moon (@{ $moons }) {
    $energy += $moon->energy();
   }

  return $energy;
 }

sub move {
  my ($moons) = @_;

  # First apply gravity
  for (my $i = 0; $i < @{ $moons } - 1; $i++) {
    for (my $j = $i + 1; $j < @{ $moons }; $j++) {
     $moons->[$i]->gravity( $moons->[$j] );
    }
   }

  # Then apply velocity
  for my $moon (@{ $moons }) {
    $moon->move();
#    $moon->print();
   }

  return;
 }

my $moons = [];

my $input_file = $ARGV[0] || 'input12.txt';

for (path( $input_file )->lines_utf8( { chomp => 1 } )) {
  push @{ $moons }, Moon->new( $_ );
 }

my $steps = $ARGV[1] || 3;
for (my $i = 0; $i < $steps; $i++) {
  move( $moons );
 }

print "After $steps the energy of the system is ", energy( $moons ), "\n";

exit;
