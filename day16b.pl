#!/usr/bin/env perl
#
# $Id: $
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package FFT;

  #
  # Note: At first I tried to do this with a string, but it was MUCH
  # MUCH slower than with an array.
  #
  sub phase {
    my ($self) = @_;

    my $count = -1;
    my $sum = 0;
    while ($count >= -@{ $self->{ val } }) {
      $sum += $self->{ val }[ $count ];
      $self->{ val }[ $count ] = $sum % 10;
      $count--;
     }

    return $self;
   }

  sub new {
    my ($class, $input) = @_;
    my $self = {
      offset => '',
      val => [],
      pattern => [ 0, 1, 0, -1 ],
    };
    $self->{ offset } = substr( $input, 0, 7 );
    my $val = substr( $input, $self->{ offset } % length( $input ) );
    my $rounds = int( ( 10000 * length( $input ) - $self->{ offset } ) / length( $input ) );
    $val .= $input x $rounds;
    $self->{ val } = [ split( '', $val ) ];

    bless $self, $class;
    return $self;
   }
}

my $input = $ARGV[0] || Path::Tiny::path( 'input16.txt' )->slurp_utf8();
chomp $input;

my $fft = FFT->new( $input );

for my $i (1..100) {
  $fft->phase();
  print "After phase $i : ", @{ $fft->{ val } }[ 0 .. 7 ], "\n";
 }

exit;
