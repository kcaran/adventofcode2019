#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Grid;

  sub print {
    my ($self) = @_;
    my $p = '';

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
    for my $n ( [-1, 0], [0, -1], [0, 1], [1, 0] ) {
      my $n_row = $row + $n->[0];
      my $n_col = $col + $n->[1];

      if ($n_row == -1) {
        my $up = $self->{ up } || next;
        $neighbors++ if ($up->{ grid }[1][2] eq '#');
       }
      elsif ($n_row == 5) {
        my $up = $self->{ up } || next;
        $neighbors++ if ($up->{ grid }[3][2] eq '#');
       }
      elsif ($n_col == -1) {
        my $up = $self->{ up } || next;
        $neighbors++ if ($up->{ grid }[2][1] eq '#');
       }
      elsif ($n_col == 5) {
        my $up = $self->{ up } || next;
        $neighbors++ if ($up->{ grid }[2][3] eq '#');
       }
      elsif ($n_row == 2 && $n_col == 2) {
        my $down = $self->{ down } || next;
        if ($row == 1 && $col == 2) {
          for my $dc (0 .. 4) {
            $neighbors++ if ($down->{ grid }[0][$dc] eq '#');
           }
         }
        elsif ($row == 3 && $col == 2) {
          for my $dc (0 .. 4) {
            $neighbors++ if ($down->{ grid }[4][$dc] eq '#');
           }
         }
        elsif ($row == 2 && $col == 1) {
          for my $dr (0 .. 4) {
            $neighbors++ if ($down->{ grid }[$dr][0] eq '#');
           }
         }
        elsif ($row == 2 && $col == 3) {
          for my $dr (0 .. 4) {
            $neighbors++ if ($down->{ grid }[$dr][4] eq '#');
           }
         }
       }
      else {
        $neighbors++ if ($self->{ grid }[$n_row][$n_col] eq '#');
       }
     }

    return $neighbors;
   }

  sub minute {
    my ($self) = @_;

    for my $row (0 .. $self->{ size } - 1) {
      for my $col (0 .. $self->{ size } - 1) {
        next if ($row == 2 && $col == 2);
        my $neighbors = $self->neighbors( $row, $col );
        if ($self->{ grid }[$row][$col] eq '.') {
          $self->{ next }[$row][$col] = ($neighbors == 1 || $neighbors == 2) ? '#' : '.';
         }
        else {
          $self->{ next }[$row][$col] = ($neighbors == 1) ? '#' : '.';
         }
       }
     }

    return $self;
   }

  sub new {
    my ($class, $input) = @_;
    my $self = {
      grid => [],
      next => [],
      up => undef,
      down => undef,
    };
    bless $self, $class;

    $input ||= ".....\n" x 5;
    for my $line (split( "\n", $input)) {
      push @{ $self->{ grid } }, [ split( '', $line ) ];
     }
    $self->{ size } = @{ $self->{ grid } };
    $self->{ next }[2][2] = '.';

    return $self;
   }
}

my $input_file = $ARGV[0] || 'input24.txt';
my $input = Path::Tiny::path( $input_file )->slurp_utf8();
my $minutes = $ARGV[1] || 200;

my $root = Grid->new( $input );
while ($minutes) {
  $minutes--;
  my $top = Grid->new();
  $root->{ up } = $top;
  $top->{ down } = $root;
  $root = $top;
  my $grid = $root;
  while ($grid->{ down }) {
    $grid->minute();
    $grid = $grid->{ down };
   }
  $grid->{ down } = Grid->new();
  $grid->{ down }{ up } = $grid;
  $grid->minute();
  $grid = $grid->{ down };
  $grid->minute();

  $grid = $root;
  while ($grid) {
    $grid->{ grid } = $grid->{ next };
    $grid->{ next } = [];
    $grid->{ next }[2][2] = '.';
    $grid = $grid->{ down };
   }
 }

# Count the bugs
my $bugs = 0;
my $grid = $root;
while ($grid) {
  my $print = $grid->print();
  my $num = () = ($print =~ /#/g);
  $bugs += $num;
# print "$bugs($num)\n$print\n\n" if ($num);
  $grid = $grid->{ down };
 }

print "The number of bugs is $bugs\n";

exit;
