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
      return $pass->[1] if ($pass->[0] eq $pos and !$maze->{ taken }{ $pass->[1] });
      return $pass->[0] if ($pass->[1] eq $pos and !$maze->{ taken }{ $pass->[0] });
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
    push @moves, ($y - 1) . ',' . $x if ($y > 0 && $maze->{ map }[$y-1][$x] eq '.');
    push @moves, ($y + 1) . ',' . $x if ($y < @{ $maze->{ map } } - 1 && $maze->{ map }[$y+1][$x] eq '.');
    push @moves, $y . ',' . ($x - 1) if ($x > 0 && $maze->{ map }[$y][$x-1] eq '.');
    push @moves, $y . ',' . ($x + 1) if ($x < @{ $maze->{ map }[$y] } - 1 && $maze->{ map }[$y][$x+1] eq '.');

    return grep { !$maze->{ taken }{ $_ } || $maze->{ taken }{ $_ } != 1 } @moves;
   }

  sub move {
    my ($self, $pos) = @_;

    ($self->{ y }, $self->{ x }) = split( ',', $pos );
 
    if ($maze->{ pass }{ 'ZZ' }[0] eq $pos) {
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
        push @{ $self->{ pass }{ $pass } }, ($y - 2) . ',' . ($index - 3) if (substr( $row, $index - 1, 1) eq '.');
        push @{ $self->{ pass }{ $pass } }, ($y - 2) . ',' . ($index) if (substr( $row, $index + 2, 1) eq '.');
       }

      while ($row =~ /\W([A-Z])\W/g) {
        my $pass = $1;
        my $index = $-[1];
        my $next = substr( $input[$y+1], $index, 1 );
        if ($next =~ tr/A-Z//) {
          push @{ $self->{ pass }{ "$pass$next" } }, ($y - 3) . ',' . ($index - 2) if (substr( $input[$y - 1], $index, 1 ) eq '.');
          push @{ $self->{ pass }{ "$pass$next" } }, ($y) . ',' . ($index - 2) if ($y < @input - 2 && substr( $input[$y + 2], $index, 1 ) eq '.');
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
my $start = $maze->{ pass }{ 'AA' }[0];
my @moves = ( Move->new( $start ) );
while (@moves) {
  my $curr = shift @moves;
  my @nextmoves = $curr->nextmoves();
# print "The next moves for ($curr->{y},$curr->{x}) are ", join( ' + ', @nextmoves ), "\n";
  for my $next (@nextmoves) {
    my $nmove = dclone( $curr );
    $nmove->move( $next );
    push @moves, $nmove;
   }
 }

exit;
