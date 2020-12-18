#!/usr/bin/perl
#
use strict;
use warnings;

use Path::Tiny;

{ package Maze;

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
     map => [],
     pass => {},
    };

    my @input = Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } );

    # Get passes from first two rows
    for my $i (0 .. length( $input[0] ) - 1) {
      my $first = substr( $input[0], $i, 1 );
      next unless ($first =~ tr/A-Z//);
      my $second = substr( $input[1], $i, 1 );
      $self->{ pass }{ "${first}${second}" } = [ "0,$i" ];
     }

    for my $y (2 .. @input - 2) {
      my $row = $input[$y];
      my $len = length( $row ) - 4;
      while ($row =~ /([A-Z]{2})/g) {
        my $pass = $1;
        my $index = $-[1];
        push @{ $self->{ pass }{ $pass } }, ($y - 2) . ',' . ($index - 1) if (substr( $row, $index - 1, 1) eq '.');
        push @{ $self->{ pass }{ $pass } }, ($y - 2) . ',' . ($index + 2) if (substr( $row, $index + 2, 1) eq '.');
       }

      while ($row =~ /\W([A-Z])\W/g) {
        my $pass = $1;
        my $index = $-[1];
        my $next = substr( $input[$y+1], $index, 1 );
        if ($next =~ tr/A-Z//) {
          push @{ $self->{ pass }{ "$pass$next" } }, ($y - 1) . ',' . $index if (substr( $input[$y - 1], $index, 1) eq '.');
          push @{ $self->{ pass }{ "$pass$next" } }, ($y + 2) . ',' . $index if ($y < @input - 2 && substr( $input[$y + 2], $index, 1) eq '.');
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

my $maze = Maze->new( $input_file );

exit;
