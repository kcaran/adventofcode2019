#!/usr/bin/env perl
#
# $Id: $
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package FFT;

  sub phase {
    my ($self) = @_;
    my $count = 0;
    my @input = split '', $self->{ val };
    my @signal = ();
    for (my $i = 1; $i <= @input; $i++) {
      my $repeat = $i;
      my $p = 0;
      my $output = 0;
      for my $digit (@input) {
        --$repeat;
        if ($repeat == 0) {
          $p = ($p + 1) % @{ $self->{ pattern } };
          $repeat = $i;
         }
        $output += $digit * $self->{ pattern }[$p];
       }
      push @signal, abs( $output ) % 10;
     }

    $self->{ val } = join( '', @signal );

    return $self;
   }

  sub new {
    my ($class, $input) = @_;
    my $self = {
      val => $input,
      pattern => [ 0, 1, 0, -1 ],
    };

    bless $self, $class;
    return $self;
   }
}

my $input = $ARGV[0] || Path::Tiny::path( 'input16.txt' )->slurp_utf8();
chomp $input;

my $fft = FFT->new( $input );

for my $i (1..100) {
  print "After phase $i : ", substr( $fft->phase()->{ val }, 0, 8 ), "\n";
 }

exit;
