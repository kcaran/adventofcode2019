#!/usr/bin/perl
#
# $Id: pl.template,v 1.2 2014/07/18 15:01:38 caran Exp $
#
use strict;
use warnings;

use Path::Tiny;

my $input_file = $ARGV[0] || 'input06.txt';

{ package Object;

  sub add_orbiter {
    my ($self, $object) = @_;
    push @{ $self->{ orbited_by } }, $object;
    return $self;
   }

  sub count_orbits {
    my ($self, $objects) = @_;
    my $count = 0;
    my $obj = $self;
    while ($obj->{ orbiting }) {
      $count++;
      $obj = $objects->{ $obj->{ orbiting } };
     }

    return $count;
   }

  sub new {
    my ($class, $object, $orbit) = @_;
    my $self = {
      id => $object,
      orbiting => $orbit,
      orbited_by => [],
    };

    bless $self, $class;
    return $self;
   }
}

{ package Path;

  sub calc_next {
    my ($self, $pos) = @_;
    my @next = ();

    my $orbiting = $self->{ objects }{ $pos }{ orbiting };
    if ($orbiting) {
	  push @next, $orbiting unless ($self->{ seen }{ $orbiting });
      $self->{ seen }{ $orbiting } = 1;
     }

    for my $o (@{ $self->{ objects }{ $pos }{ orbited_by } }) {
	  push @next, $o unless ($self->{ seen }{ $o });
      $self->{ seen }{ $o } = 1;
     }

    return @next;
   }

  sub calc_transfers {
    my ($self) = @_;

    my $positions = [ 'YOU' ];
    my $transfers = 0;

    while (@{ $positions }) {
      my $new_positions = [];
      for my $pos (@{ $positions }) {
        # Don't count the first or last transfer (orbit to orbit)
        return ($transfers - 2) if ($pos eq 'SAN');
        push @{ $new_positions }, $self->calc_next( $pos );
       }
      $positions = $new_positions;
      $transfers++;
     }

    return $transfers;
   }

  sub new {
    my ($class, $objects) = @_;
    my $self = {
      objects => $objects,
      seen => { 'YOU' => 1 },
      santa => 0,
    };

    bless $self, $class;
    return $self;
   }
}

# Start with the COM - it doesn't orbit anything
my $objects = { COM => Object->new( 'COM', '' ) };

for (path( $input_file )->lines_utf8( { chomp => 1 } )) {
  my ($orbit, $object) = split /\)/, $_;
  $objects->{ $object } = Object->new( $object, $orbit );
 }

my $orbits = 0;
for my $obj_name (keys %{ $objects }) {
  # Calculate the orbiters now that we have all the objects
  my $obj = $objects->{ $obj_name };
  $objects->{ $obj->{ orbiting } }->add_orbiter( $obj_name ) if ($obj->{ orbiting });
  $orbits += $obj->count_orbits( $objects );
 }

print "The number or orbits is $orbits\n";

my $path = Path->new( $objects );
print "The mininum number of transfers is ", $path->calc_transfers(), "\n";

exit;
