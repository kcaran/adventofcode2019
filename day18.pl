#!/usr/bin/env perl
#
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use Storable 'dclone';

{ package Map;

  sub unlock_door {
    my ($self, $key) = @_;
    $self->{ keys_left }--;
    my $door_pos = $self->{ doors }{ uc( $key ) };
    $self->{ map }[$door_pos->[0]][$door_pos->[1]] = '.' if ($door_pos);
    return $self;
   }

  sub move {
    my ($self, $y, $x) = @_;

    my $new_y = $self->{ pos }[0] + $y;
    my $new_x = $self->{ pos }[1] + $x;
    my $prev = $self->{ prev_moves }{ "$new_y,$new_x" } || '';
    my $point = $self->{ map }[$new_y][$new_x];
    return if ($prev eq $self->{ keys_left });
    return if ($point eq '#' || ($point ge 'A' && $point le 'Z'));

    my $new = Storable::dclone( $self );
    if ($point ge 'a' && $point le 'z') {
      $new->unlock_door( $point );
	  $new->{ map }[$new_y][$new_x] = '.';
     }

    $new->{ pos } = [ $new_y, $new_x ];
    $new->{ prev_moves }{ "$new_y,$new_x" } = $new->{ keys_left };

    return $new;
   }

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
     map => [],
     start => [],
     doors => {},
     pos => [],
     keys_left => 0,
     prev_moves => {},
    };

    my $x = 0;
    my $y = 0;
    for my $row ( Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
      $x = 0;
      for my $col (split( '', $row )) {
        if ($col eq '@') {
          $self->{ start } = [ $y, $x ];
          $col = '.';
         }
        $self->{ map }[$y][$x] = $col;
        $self->{ doors }{ $col } = [ $y, $x ] if ($col ge 'A' and $col le 'Z');
        $self->{ keys_left }++ if ($col ge 'a' and $col le 'z');
        $x++;
       }
      $y++;
     }

    $self->{ pos }[0] = $self->{ start }[0];
    $self->{ pos }[1] = $self->{ start }[1];

    $self->{ num_cols } = $x;
    $self->{ num_rows } = $y;
    $self->{ prev_moves }{ "$self->{ pos }[0],$self->{ pos }[1]" } = $self->{ keys_left };

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input18.txt';

my $moves = [ Map->new( $input_file ) ];
my $num_moves = 0;
while (@{ $moves }) {
  my $new_moves = [];
  $num_moves++;
  for my $m (@{ $moves }) {
    for my $dir ([ 0, 1 ], [ 0, -1 ], [ -1, 0 ], [ 1, 0 ]) {
      my $next = $m->move( $dir->[0], $dir->[1] );
      next unless ($next);
      die "We found all the keys in $num_moves\n" if ($next->{ keys_left } == 0);
      push @{ $new_moves }, $next;
     }
   }
  $moves = $new_moves;
print "Move $num_moves has ", scalar @{ $moves }, " possible moves.\n";
 }

print "We did not find all of the keys. :-(\n";
exit;
