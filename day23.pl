#!/usr/bin/env perl
#
# Use inheritance to override IntCode functions!
#

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Storable 'dclone';

#Term::ReadKey::ReadMode( 'cbreak' );

use IntCode;

my $comp;
my $nat;
my $nat_hist = -1;

{ package MyProgram;

  use parent 'IntCode';

  sub read_input {
    my ($self) = @_;

    $self->{ input } = [ -1 ] unless( @{ $self->{ input } } );

    return ($self);
   }

  sub write_output {
    my ($self) = @_;

    return unless (@{ $self->{ output } } == 3);
#    print "$self->{ addr } sends @{ $self->{ output } }\n";

    if ($self->{ output }[0] == 255) {
      $nat = [ @{ $self->{ output } }[1 .. 2] ];
     }
    else {
      push @{ $comp->[ $self->{ output }[0] ]{ input } }, @{ $self->{ output } }[1 .. 2];
     }
    $self->{ output } = [];

    return;
   }

};

for my $i (0 .. 49) {
  $comp->[$i] = MyProgram->new( 'input23.txt' );
  $comp->[$i]{ input } = [ $i ];
  $comp->[$i]{ addr } = $i;
 }

my $idle = 0;
while (1) {
  for my $i (0 .. 49) {
    $comp->[$i]->step();
   }

  #
  # Check if they computers are idle - Note that you have to wait a long
  # time for them to be idle!
  #
  unless (!$nat || (grep { @{ $_->{ input } } > 0 } @{ $comp })
	|| (grep { @{ $_->{ output } } > 0 } @{ $comp })) {
    $idle++;
    if ($idle > 1000) {
      die "$nat->[1] was sent twice" if ($nat_hist == $nat->[1]);
      $nat_hist = $nat->[1];
      print "NAT sends @{ $nat }\n";
      $comp->[0]{ input } = [ @{ $nat } ];
      $nat = undef;
      $idle = 0;
     }
   }
  else {
      $idle = 0;
   }

  next;
 }

Term::ReadKey::ReadMode( 'normal' );

exit;
