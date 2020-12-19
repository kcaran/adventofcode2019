#!/usr/bin/perl
#
use strict;
use warnings;

use Path::Tiny;
use Storable 'dclone';

my $maze;

{ package Move;

  sub is_portal {
    my ($self) = @_;

    my $pos = "$self->{ y },$self->{ x }";

    for my $portal (keys %{ $maze->{ pass } }) {
      next if ($portal eq 'AA' || $portal eq 'ZZ');
      my $pass = $maze->{ pass }{ $portal };
      if ($pass->[0] eq $pos && $self->{ level } > 0) {
        my $newlevel = $self->{ level } - 1;
        if (!$maze->{ taken }{ "$pass->[1],$newlevel" }) {
          return "$pass->[1],$newlevel";
         }
       }
      if ($pass->[1] eq $pos) {
        my $newlevel = $self->{ level } + 1;
        if (!$maze->{ taken }{ "$pass->[0],$newlevel" }) {
          return "$pass->[0],$newlevel";
         }
       }
     }

    return;
   }

  sub nextmoves {
    my ($self) = @_;

    my $portal = $self->is_portal();
    return $portal if ($portal);

    my @moves = ();
    my $x = $self->{ x };
    my $y = $self->{ y };
    my $level = $self->{ level };
    push @moves, ($y - 1) . ',' . $x . ",$level" if ($y > 0 && $maze->{ map }[$y-1][$x] eq '.');
    push @moves, ($y + 1) . ',' . $x . ",$level" if ($y < @{ $maze->{ map } } - 1 && $maze->{ map }[$y+1][$x] eq '.');
    push @moves, $y . ',' . ($x - 1) . ",$level" if ($x > 0 && $maze->{ map }[$y][$x-1] eq '.');
    push @moves, $y . ',' . ($x + 1) . ",$level" if ($x < @{ $maze->{ map }[$y] } - 1 && $maze->{ map }[$y][$x+1] eq '.');

    return grep { !$maze->{ taken }{ $_ } || $maze->{ taken }{ $_ } != 1 } @moves;
   }

  sub move {
    my ($self, $pos) = @_;

    ($self->{ y }, $self->{ x }, $self->{ level }) = split( ',', $pos );
 
    if ("$maze->{ pass }{ 'ZZ' }[0],0" eq $pos) {
      die "We completed the maze in ", $self->{ steps }, "\n";
     }
    $self->{ steps }++;
    $maze->{ taken }{ $pos } = 1;

    return $self;
   }

  sub new {
    my ($class, $pos) = @_;
    my $self = {
     steps => 0,
     level => 0,
    };
    bless $self, $class;

    $self->move( $pos );
    return $self;
   }
}

{ package Maze;

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
     map => [],
     pass => {},
     taken => {},
    };

    my @input = Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } );

    # Get passes from first two rows
    for my $i (2 .. length( $input[0] ) - 3) {
      my $first = substr( $input[0], $i, 1 );
      next unless ($first =~ tr/A-Z//);
      my $second = substr( $input[1], $i, 1 );
      $self->{ pass }{ "${first}${second}" } = [ '0,' . ($i - 2) ];
     }

    for my $y (2 .. @input - 2) {
      my $row = $input[$y];
      my $len = length( $row ) - 4;
      while ($row =~ /([A-Z]{2})/g) {
        my $pass = $1;
        my $index = $-[1];
        my $inner = ($index > 0 && $index < length( $row ) - 2) ? 1 : 0;
        $self->{ pass }{ $pass }[$inner] = ($y - 2) . ',' . ($index - 3) if (substr( $row, $index - 1, 1) eq '.');
        $self->{ pass }{ $pass }[$inner] = ($y - 2) . ',' . ($index) if (substr( $row, $index + 2, 1) eq '.');
       }

      while ($row =~ /\b([A-Z])\b/g) {
        my $pass = $1;
        my $index = $-[1];
        my $inner = ($y < @input - 3) ? 1 : 0;
        my $next = substr( $input[$y+1], $index, 1 );
        if ($next =~ tr/A-Z//) {
          $self->{ pass }{ "$pass$next" }[$inner] = ($y - 3) . ',' . ($index - 2) if (substr( $input[$y - 1], $index, 1 ) eq '.');
          $self->{ pass }{ "$pass$next" }[$inner] = ($y) . ',' . ($index - 2) if ($y < @input - 2 && substr( $input[$y + 2], $index, 1 ) eq '.');
         } 
       }

      for my $x (2 .. length( $row ) - 3) {
        my $c = substr( $row, $x, 1 );
        $self->{ map }[$y - 2][$x - 2] = $c if ($c =~ tr/.#//);
       }
     }

    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input20.txt';

$maze = Maze->new( $input_file );
my $start = $maze->{ pass }{ 'AA' }[0] . ",0";
my @moves = ( Move->new( $start ) );
while (@moves) {
  my $curr = shift @moves;
  my @nextmoves = $curr->nextmoves();
# print "The next moves for ($curr->{y},$curr->{x},$curr->{level}) are ", join( ' + ', @nextmoves ), "\n";
  for my $next (@nextmoves) {
    my $nmove = dclone( $curr );
    $nmove->move( $next );
    push @moves, $nmove;
   }
 }

exit;
