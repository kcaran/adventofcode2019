#!/usr/bin/env perl
#
# I thought I did this wrong when I came back to it in 2023. But it
# turned out I had the right idea: for each bot, find all the keys
# you can see. I think it could be faster if I did better caching
# of previous results, but this works!
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

my $map;

my $state;

{ package Map;

  sub next_keys {
    my ($self, $initial, $bot) = @_;
    my @key_moves;

    $self->{ prev_moves } = {};
    my @moves = ( $initial );

    my (@y, @x, $cnt, $keys);
    ($y[0], $x[0], $y[1], $x[1], $y[2], $x[2], $y[3], $x[3], $keys, $cnt) = split( ',', $initial );
    $keys ||= '';

    @moves = ( "$y[$bot],$x[$bot],$keys,$cnt" );

    while (@moves) {
      my $move = shift @moves;

      my ($y, $x, $keys, $cnt) = split( ',', $move );
      my $point = $self->{ map }[$y][$x];
      if ($point ge 'a' && $point le 'z' && index( $keys, $point ) < 0) {
        $y[$bot] = $y;
        $x[$bot] = $x;
        my $new_pos = join( ',', map{ "$y[$_],$x[$_]" } 0 .. 3 );
        my $new_keys = join( '', sort split( '', "${keys}${point}" ) );

        if (!$state->{ $new_keys } || $state->{ $new_keys } > $cnt) {
          $state->{ $new_keys } = $cnt;
          print "$new_keys == $cnt\n";
         }
        if (length( $new_keys ) == keys %{ $self->{ key } }) {
          if ($self->{ min_path } < 0 || $self->{ min_path } > $cnt) {
            $self->{ min_path } = $cnt;
           }
         }
        push @key_moves, "$new_pos,$new_keys,$cnt";
        next;
       }
      push @moves, $self->valid_moves( $move );
     }

    return @key_moves;
   }

  sub valid_moves {
    my ($self, $move) = @_;
    my @moves = ();

    my ($y, $x, $keys, $cnt) = split( ',', $move );
    $cnt++;
    for my $dir ([ 0, 1 ], [ 0, -1 ], [ -1, 0 ], [ 1, 0 ]) {
      my $new_y = $y + $dir->[0];
      my $new_x = $x + $dir->[1];

      my $new_pos = "$new_y,$new_x";
      next if ($self->{ prev_moves }{ $new_pos });
      $self->{ prev_moves }{ $new_pos } = 1;

      my $point = $self->{ map }[$new_y][$new_x];
      next if ($point eq '#');
      next if (($point ge 'A' && $point le 'Z') && index( $keys, lc( $point )) < 0);
      push @moves, "$new_pos,$keys,$cnt";
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
    };

    my ($x, $y) = (0, 0);
    my @start;
    for my $row ( Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
      $x = 0;
      for my $col (split( '', $row )) {
        if ($col eq '@') {
          @start  = ( $y, $x );
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
    $self->{ start } = join( ',', $y-1, $x-1, $y+1, $x-1, $y-1, $x+1, $y+1, $x+1, undef, 0 );

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input18.txt';

$map = Map->new( $input_file );

my %seen;
my @moves = ( $map->start() );
while (@moves) {
  my $move = shift @moves;
  my @split = split( ',', $move );
  my $cnt = pop @split;
  my $key = join( ',', @split );
  next if ($seen{ $key } && $seen{ $key } <= $cnt);
  $seen{ $key } = $cnt;
  for my $bot (0 .. 3) {
    push @moves, $map->next_keys( $move, $bot );
   }
 }

print "We found all the keys in $map->{ min_path } moves.\n";

exit;
