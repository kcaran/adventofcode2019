#!/usr/bin/env perl
#
# Note: The math escapes me a bit on this. How would I ever solve it?
# https://www.reddit.com/r/adventofcode/comments/ee0rqi/comment/fbtugcu/?utm_source=share&utm_medium=web2x&context=3
#
# It did give me a chance to use Perl's Math::BigInt
#
use strict;
use warnings;
use utf8;

use Math::BigInt;
use Path::Tiny;

{ package Deck;

  sub cut {
    my ($self, $inc) = @_;

    $self->{ b } = ($self->{ b } - $inc) % $self->{ size };

    return $self;
   }

  sub deal {
    my ($self, $inc) = @_;

    $self->{ a } = $self->{ a } * $inc % $self->{ size };
    $self->{ b } = $self->{ b } * $inc % $self->{ size };

    return $self;
   }

  sub reverse {
    my ($self) = @_;

    $self->{ a } = -$self->{ a } % $self->{ size };
    $self->{ b } = ($self->{ size } - $self->{ b } - 1) % $self->{ size };

    return $self;
   }

  sub pos {
    my ($self, $card) = @_;

    return $self->{ card };
   }

  sub shuffle {
    my ($self, $inst) = @_;

    if ($inst =~ /^deal with increment (\d+)/) {
      $self->deal( $1 );
     }
    elsif ($inst =~ /^deal into new stack/) {
      $self->reverse( $1 );
     }
    elsif ($inst =~ /^cut (-?\d+)/) {
      $self->cut( $1 );
     }
    elsif ($inst =~ /^Result: (.*?)$/) {
      my $result = $1;
      my $print = join( ' ', @{ $self->{ deck } } );
      print "Result of $result " . ($result eq $print ? "matches\n" : "*doesn't match* $print!\n");
     }
    else {
      die "Illegal instruction $inst";
     }

    return $self;
   }

  sub new {
    my ($class, $input_file) = @_;
    my $self = {
     size => 119315717514047,
     shuffles => 101741582076661,
     a => 1,
     b => 0,
    };

    $self->{ inst } = [ Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } ) ];

    bless $self, $class;
    return $self;
   }
}

my $input_file = 'input22.txt';

my $deck = Deck->new( $input_file );

for my $inst (@{ $deck->{ inst } }) {
  $deck->shuffle( $inst );
 }

my $pos = 2020;

my $r = Math::BigInt->new( 1 - $deck->{ a } );
$r = $r->bmodpow( $deck->{ size } - 2, $deck->{ size } );
$r = ($deck->{ b } * $r) % $deck->{ size };

my $card = Math::BigInt->new( $deck->{ a } );
my $exp = Math::BigInt->new( $deck->{ shuffles } );
$exp = $exp->bmul( $deck->{ size } - 2 );
$card = $card->bmodpow( $exp, $deck->{ size } );
$card = (($pos - $r) * $card + $r) % $deck->{ size };

print "The card at $pos is $card\n";

exit;
