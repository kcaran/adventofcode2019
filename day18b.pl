#!/usr/bin/env perl
#
# I had to re-write this for part b - I made it simpler to make it
# pass the tests, but for the input taking a single step in each
# direction was much much too slow!
#
# Next is that I was memoizing with the counts - We should only include
# the minimum steps to get to that position with keys!
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use Storable 'dclone';

my $map;

my $state;

{ package Map;

  sub valid_moves {
    my ($self, $move) = @_;
    my @moves = ();

    my (@y, @x, $cnt, $keys);
    ($y[0], $x[0], $y[1], $x[1], $y[2], $x[2], $y[3], $x[3], $keys) = split( ',', $move );
    $keys ||= '';
    $cnt = $self->{ prev_moves }{ $move } + 1;

    return @moves if ($self->{ min_path } > 0 && $cnt > $self->{ min_path });
    for my $bot (0 .. 3) {
    for my $dir ([ 0, 1 ], [ 0, -1 ], [ -1, 0 ], [ 1, 0 ]) {
      my @new_y = @y;
      my @new_x = @x;
      my $new_cnt = $cnt;
      $new_y[$bot] = $y[$bot] + $dir->[0];
      $new_x[$bot] = $x[$bot] + $dir->[1];

      my $point = $self->{ map }[$new_y[$bot]][$new_x[$bot]];
      next if ($point eq '#');

      # Move in the same direction if a hallway
      if ($dir->[0] == 0) {
        while ($self->{ map }[$y[$bot] - 1][$new_x[$bot]] eq '#'
            && $self->{ map }[$y[$bot] + 1][$new_x[$bot]] eq '#'
            && $self->{ map }[$y[$bot]][$new_x[$bot]+$dir->[1]] eq '.') {
          $new_x[$bot] += $dir->[1];
          $new_cnt++;
         }
       }
      else {
        while ($self->{ map }[$new_y[$bot]][$x[$bot] - 1] eq '#'
            && $self->{ map }[$new_y[$bot]][$x[$bot] + 1] eq '#'
            && $self->{ map }[$new_y[$bot]+$dir->[0]][$x[$bot]] eq '.') {
          $new_y[$bot] += $dir->[0];
          $new_cnt++;
         }
       }

      next if (($point ge 'A' && $point le 'Z') && index( $keys, lc( $point )) < 0);

      my $new_pos = join( ',', map{ "$new_y[$_],$new_x[$_]" } 0 .. 3 );
      next if ($self->{ prev_moves }{ "$new_pos,$keys" }
			&& $self->{ prev_moves }{ "$new_pos,$keys" } <= $new_cnt);

      my $new_keys = $keys;
      if ($point ge 'a' && $point le 'z' && index( $keys, $point ) < 0) {
        $new_keys = join( '', sort split( '', "${keys}${point}" ) );
        if (!$state->{ $new_keys } || $state->{ $new_keys } > $new_cnt) {
          $state->{ $new_keys } = $cnt;
          print "$new_keys == $cnt\n";
         }
        if (length( $new_keys ) == keys %{ $self->{ key } }) {
          if ($self->{ min_path } < 0 || $self->{ min_path } > $new_cnt) {
            $self->{ min_path } = $new_cnt;
           }
         }
       }

      push @moves, "$new_pos,$new_keys";
      $self->{ prev_moves }{ "$new_pos,$new_keys" } = $new_cnt;
     }
     }

    return @moves;
   }

  sub start {
    my ($self) = @_;

    return $self->{ start };
   }

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
     map => [],
     key => {},
     min_path => -1,
     prev_moves => {},
    };

    my ($x, $y) = (0, 0);
    my @start;
    for my $row ( Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
      $x = 0;
      for my $col (split( '', $row )) {
        if ($col eq '@') {
          @start = ( $y, $x );
          $col = '.';
         }
        elsif ($col ge 'a' && $col le 'z') {
          $self->{ key }{ $col } = [ $y, $x ];
         }
        $self->{ map }[$y][$x] = $col;
        $x++;
       }
      $y++;
     }

    $self->{ num_keys } = keys %{ $self->{ keys } };

    # Update map for part b
    ($y, $x) = @start;
    $self->{ map }[$y-1][$x] = '#';
    $self->{ map }[$y+1][$x] = '#';
    $self->{ map }[$y][$x-1] = '#';
    $self->{ map }[$y][$x+1] = '#';
    $self->{ start } = join( ',', $y-1, $x-1, $y+1, $x-1, $y-1, $x+1, $y+1, $x+1, undef );

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input18.txt';

$map = Map->new( $input_file );

my @moves = ( $map->start() );

while (@moves) {
  my $move = shift @moves;
# print "For $move there are now ", scalar( @moves ), " moves\n";
  push @moves, $map->valid_moves( $move );
 }

print "We found all the keys in $map->{ min_path } moves.\n";

exit;
