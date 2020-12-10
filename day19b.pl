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

{ package Beam;

  my $size = $ARGV[0] || 100;

  # Assume beam always goes to the right
  sub bounds {
    my ($self) = @_;
    
    my $row = ++$self->{ row };
    my $max_x = $self->{ max_x };
    while ($program->init->run( $max_x, $row )->[0] == 0) {
      $max_x++;
     }
    while ($program->init->run( $max_x, $row )->[0] == 1) {
      $max_x++;
     }

    $self->{ max_x } = $max_x - 1;
    return $self;
   }

  sub box {
   my ($self) = @_;

   while (1) {
     $self->bounds(); 
     next if ($self->{ max_x } < $size);
     if ($program->init->run( $self->{ max_x } - $size + 1, $self->{ row } + $size - 1)->[0] == 1) {
      return ($self->{ max_x } - $size + 1) * 10000 + $self->{ row };
     }
    }

   return;
  }

  sub new {
    my ($class, $start_x, $start_y) = @_;

    my $self = {
      max_x => $start_x,
      row => $start_y,
    };

   bless $self, $class;

   return $self;
  }
}

use Data::Dumper;

my $count = 0;

#
# In graphing the tractor beam, it seems the beam skips the first two
# rows :-(
#
my $beam = Beam->new( 4, 3 );
print "The score is ", $beam->box(), "\n";

exit;
