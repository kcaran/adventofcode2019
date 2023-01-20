#!/usr/bin/env perl
#
# I had to cheat a little and look at reddit:
#
# https://www.reddit.com/r/adventofcode/comments/ecsw02/2019_day_18_missing_a_critical_step_of_the/
#
# You can think about this as a dynamic programming problem, with the
# state being (x, y, keys collected).
#
# You start at a particular bot position with 0 keys, i.e. your state is
# (bx, by, 0). You want to find the best possible score from this state,
# which we'll call score(bx, by, 0) (representing keys as a bitfield).
# There are a set of keys that you can reach, and the best score across
# all reachable keys is something like
#
# def score(x, y, keys):
#   return min([score(key_x, key_y, new_key | keys) + steps_to(key_x, key_y)
#                for (key_x, key_y, new_key) in reachable(x, y, keys)])
# Notice that this calls score recursively; you'll want to memoize calls
# to score to cut down on evaluation time.
#
# My problem was that I was trying to update the map after every move,
# cloning the object again and again with each found key and
# each open door.
#
# I was able to get the test18d.txt down but the puzzle input still took
# a long time:
#
# ..such that a lot of times moving from key point a to b takes you via
# multiple other keys, which further cuts down on possible state
# combinations at each end.
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use Storable 'dclone';

my $map;

my $state;

sub min_path {
  my $num_keys = 0;
  my $path = 0;
  for my $k (keys %{ $state }) {
    my $len = length( $k );
    if ($len > $num_keys) {
      $num_keys = $len;
      $path = $state->{ $k };
     }
    elsif ($len == $num_keys && $path > $state->{ $k }) {
      $path = $state->{ $k };
     }
   }
  return $path;
 }

{ package Map;

  sub next_keys {
    my ($self, $initial) = @_;

    $self->{ prev_moves } = {};
    my @moves = $map->valid_moves( $initial );
    my @keys = ();

    for my $move (@moves) {
      my (@y, @x, $cnt, $keys);
      ($y[0], $x[0], $y[1], $x[1], $y[2], $x[2], $y[3], $x[3], $cnt, $keys) = split( ',', $move );
    for my $bot (0 .. 3) {
      my $point = $self->{ map }[$y[$bot]][$x[$bot]];
      if ($point ge 'a' && $point le 'z' && index( $keys, $point ) < 0) {
        $keys = $point . join( '', sort split( '', $keys ) );
        if (!$state->{ $keys } || $state->{ $keys } > $cnt) {
          my $pos = join( ',', map{ "$y[$_],$x[$_]" } 0 .. 3 );
          push (@keys, "$pos,$cnt,$keys");
          $state->{ $keys } = $cnt;
         }
        next;
       }
      push @moves, $map->valid_moves( $move );
     }
     }

    return @keys;
   }

  sub valid_moves {
    my ($self, $move) = @_;
    my @moves = ();

    my (@y, @x, $cnt, $keys);
    ($y[0], $x[0], $y[1], $x[1], $y[2], $x[2], $y[3], $x[3], $cnt, $keys) = split( ',', $move );
    $cnt++;

    for my $bot (0 .. 3) {
    for my $dir ([ 0, 1 ], [ 0, -1 ], [ -1, 0 ], [ 1, 0 ]) {
      my @new_y = @y;
      my @new_x = @x;
      $new_y[$bot] = $y[$bot] + $dir->[0];
      $new_x[$bot] = $x[$bot] + $dir->[1];

      my $point = $self->{ map }[$new_y[$bot]][$new_x[$bot]];
      next if ($point eq '#');
      next if (($point ge 'A' && $point le 'Z') && index( $keys, lc( $point )) < 0);

      my $new_pos = join( ',', map{ "$new_y[$_],$new_x[$_]" } 0 .. 3 );
      next if ($self->{ prev_moves }{ $new_pos });
      $self->{ prev_moves }{ $new_pos } = 1;

      push @moves, "$new_pos,$cnt,$keys";
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

    # Update map for part b
    ($y, $x) = @start;
    $self->{ map }[$y-1][$x] = '#';
    $self->{ map }[$y+1][$x] = '#';
    $self->{ map }[$y][$x-1] = '#';
    $self->{ map }[$y][$x+1] = '#';
    $self->{ start } = join( ',', $y-1, $x-1, $y+1, $x-1, $y-1, $x+1, $y+1, $x+1, 0, undef );

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input18.txt';

$map = Map->new( $input_file );

my @moves = $map->next_keys( $map->start() );

while (@moves) {
  my $move = shift @moves;
  print "For $move, there are now ", scalar( @moves ), " moves\n";
  push @moves, $map->next_keys( $move );
 }

print "We found all the keys in ", min_path(), " moves.\n";

exit;
