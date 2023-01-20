#!/usr/bin/env perl
#
# I had to re-write this for part b - I made it simpler to make it
# pass the tests, but for the input taking a single step in each
# direction was much much too slow!
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
    ($y[0], $x[0], $y[1], $x[1], $y[2], $x[2], $y[3], $x[3], $cnt, $keys) = split( ',', $move );
    $cnt++;

    return @moves if ($self->{ min_path } > 0 && $cnt > $self->{ min_path });
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
      next if ($self->{ prev_moves }{ "$new_pos,$cnt,$keys" });

      my $new_keys = $keys;
      if ($point ge 'a' && $point le 'z' && index( $keys, $point ) < 0) {
        $new_keys = join( '', sort split( '', "${keys}${point}" ) );
        $state->{ $new_keys } = $cnt unless ($state->{ $new_keys } && $state->{ $new_keys } <= $cnt);
        if (length( $new_keys ) == keys %{ $self->{ key } }) {
          if ($self->{ min_path } < 0 || $self->{ min_path } > $cnt) {
            $self->{ min_path } = $cnt;
           }
         }
       }

      push @moves, "$new_pos,$cnt,$new_keys";
      $self->{ prev_moves }{ "$new_pos,$cnt,$new_keys" } = 1;
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
    $self->{ start } = join( ',', $y-1, $x-1, $y+1, $x-1, $y-1, $x+1, $y+1, $x+1, 0, undef );

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input18.txt';

$map = Map->new( $input_file );

my @moves = ( $map->start() );

while (@moves) {
  my $move = shift @moves;
  print "For $move there are now ", scalar( @moves ), " moves\n";
  push @moves, $map->valid_moves( $move );
 }

print "We found all the keys in $map->{ min_path } moves.\n";

exit;
