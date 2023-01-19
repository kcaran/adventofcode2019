#!/usr/bin/env perl
#
use strict;
use warnings;

use Path::Tiny;
use Math::Utils qw( lcm );

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

sub states {
  my ($moons) = @_;

  my $x = join( ',', map { $_->{ x },$_->{ vx } } @{ $moons } );
  my $y = join( ',', map { $_->{ y },$_->{ vy } } @{ $moons } );
  my $z = join( ',', map { $_->{ z },$_->{ vz } } @{ $moons } );
  return ($x, $y, $z);
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
   }

  return;
 }

my $moons = [];
my $moon_states;
my $count = 1;
my ($x_cycle, $y_cycle, $z_cycle);
my ($x_state, $y_state, $z_state);

my $input_file = $ARGV[0] || 'input12.txt';

for (path( $input_file )->lines_utf8( { chomp => 1 } )) {
  push @{ $moons }, Moon->new( $_ );
 }

#
# The axis are independent! Find how often they cycle, then determine the
# least common multiple.
#
($x_state, $y_state, $z_state) = states( $moons );
$moon_states->{ x }{ $x_state } = $count;
$moon_states->{ y }{ $y_state } = $count;
$moon_states->{ z }{ $z_state } = $count;

while (!$x_cycle || !$y_cycle || !$z_cycle) {
  move( $moons );

  # Check for cycles
  $count++;

  ($x_state, $y_state, $z_state) = states( $moons );
  if (!$x_cycle && $moon_states->{ x }{ $x_state }) {
    $x_cycle = $count - 1;
   }
  else {
    $moon_states->{ x }{ $x_state } = $count;
   }

  if (!$y_cycle && $moon_states->{ y }{ $y_state }) {
    $y_cycle = $count - 1;
   }
  else {
    $moon_states->{ y }{ $y_state } = $count;
   }

  if (!$z_cycle && $moon_states->{ z }{ $z_state }) {
    $z_cycle = $count - 1;
   }
  else {
    $moon_states->{ z }{ $z_state } = $count;
   }
 }

print "The cycle repeats itself in ", lcm( $x_cycle, $y_cycle, $z_cycle ), " moves\n";

exit;
