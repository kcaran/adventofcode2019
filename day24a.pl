#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Grid;

  sub print {
    my ($self) = @_;
    my $p;

    for my $row (@{ $self->{ grid } }) {
      $p .= join( '', @{ $row } ) . "\n";
     }

    return $p;
  }

  sub score {
    my ($self) = @_;
    my $score = 0;
    my $count = 1;
    for my $row (0 .. $self->{ size } - 1) {
      for my $col (0 .. $self->{ size } - 1) {
        $score += $count if ($self->{ grid }[$row][$col] eq '#');
        $count *=2;
       }
     }

    return $score;
   }

  sub neighbors {
    my ($self, $row, $col) = @_;

    my $neighbors = 0;
    #for my $n ( [-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]) {
    for my $n ( [-1, 0], [0, -1], [0, 1], [1, 0] ) {
      my $n_row = $row + $n->[0];
      my $n_col = $col + $n->[1];
      next if ($n_row < 0 || $n_col < 0);
      next if ($n_row >= $self->{ size } || $n_col >= $self->{ size });
      $neighbors++ if ($self->{ grid }[$n_row][$n_col] eq '#');
     }

    return $neighbors;
   }

  sub minute {
    my ($self) = @_;

    my $new = [];

    for my $row (0 .. $self->{ size } - 1) {
      for my $col (0 .. $self->{ size } - 1) {
        my $neighbors = $self->neighbors( $row, $col );
        if ($self->{ grid }[$row][$col] eq '.') {
          $new->[$row][$col] = ($neighbors == 1 || $neighbors == 2) ? '#' : '.';
         }
        else {
          $new->[$row][$col] = ($neighbors == 1) ? '#' : '.';
         }
       }
     }

    $self->{ grid } = $new;
    return $self;
   }

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
      grid => [],
      hist => {},
    };
    bless $self, $class;

    for my $line ( Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
      push @{ $self->{ grid } }, [ split( '', $line ) ];
     }
    $self->{ size } = @{ $self->{ grid } };

    return $self;
   }
}

my $input_file = $ARGV[0] || 'input24.txt';

my $grid = Grid->new( $input_file );
my $p = $grid->print();
my $minute = 0;
while (!$grid->{ hist }{ $p }) {
  $minute++;
  $grid->{ hist }{ $p } = $minute;
  $grid->minute();
  $p = $grid->print();
 }

print "The layout matches after $minute minutes with a score ", $grid->score(), "\n$p";

exit;
