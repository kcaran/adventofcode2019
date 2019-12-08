#!/usr/bin/env perl
#
# Note: Had a little trouble solving this because the 'U' looks like a 'V'
# to me!
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Image;

  sub count_digits {
    my ($str, $digit) = @_;
    my $count = 0;
    for my $c (split '', $str) {
      $count++ if ($c == $digit);
     }
    return $count;
   }

  sub check_layers {
    my ($self) = @_;

    my $max = length( $self->{ layers }[0] );
    my $layer;
    for my $l (@{ $self->{ layers } }) {
      my $zero_count = count_digits( $l, 0 );
      if ($zero_count < $max) {
        $max = $zero_count;
        $layer = $l;
       }
     }

    return count_digits( $layer, 1 ) * count_digits( $layer, 2 );
   }

  sub render_pixel {
    my ($self, $x, $y) = @_;

    my $index = $self->{ width } * $y + $x;
    my $value = 2;
    my $layer = 0;
    while ($value == 2 && $layer < @{ $self->{ layers } }) {
      $value = substr( $self->{ layers }[$layer], $index, 1 );
      $layer++;
     }

    return $value;
   }

  sub render {
    my ($self) = @_;

    for my $y (0 .. $self->{ height } - 1) {
      my $row = '';
      for my $x (0 .. $self->{ width } - 1) {
        $row .= $self->render_pixel( $x, $y ) == 0 ? 'X' : ' ';
       }
      print "$row\n";
     }
   }

  sub new {
    my ($class, $input, $width, $height) = @_;
    my $self = {
      layers => [],
      width => $width,
      height => $height,
    };

    my $index = 0;
    my $len = $width * $height;
    while ($index < length( $input )) {
      push @{ $self->{ layers } }, substr( $input, $index, $len );
      $index += $len;
     }

    bless $self, $class;
    return $self;
   }
}

#
# Note: For some reason, slurp is adding a line feed at the end of the
# input.
#
my $input_file = $ARGV[0] || 'input08.txt';
my $input = Path::Tiny::path( $input_file )->slurp_utf8();
$input =~ s/\n$//;

my $width = 25;
my $height = 6;

my $image = Image->new( $input, $width, $height );

print "The checksum is ", $image->check_layers(), "\n";

$image->render();

exit;
