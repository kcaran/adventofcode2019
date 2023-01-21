#!/usr/bin/env perl
#
# Note: Had a little trouble solving this because the 'U' looks like a 'V'
# to me!
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Deck;

  sub cut {
    my ($self, $inc) = @_;
    $self->{ deck } = [ splice( @{ $self->{ deck } }, $inc ), @{ $self->{ deck } } ];
    return $self;
   }

  sub deal {
    my ($self, $inc) = @_;

    my @new;
    my $pos = 0;
    for my $i (0 .. @{ $self->{ deck } } - 1) {
      my $card = $self->{ deck }[$i];
      $new[$pos] = $card;
      $pos = ($pos + $inc) % @{ $self->{ deck } };
     }

    $self->{ deck } = [ @new ];
    return $self;
   }

  sub reverse {
    my ($self) = @_;

    $self->{ deck } = [ reverse @{ $self->{ deck } } ];

    return $self;
   }

  sub pos {
    my ($self, $card) = @_;

    my $i = 0;
    while ($self->{ deck }[$i] != $card) {
      $i++;
     }

    return $i;
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
    my ($class, $input_file, $size) = @_;
    my $self = {
    };

    $self->{ inst } = [ Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } ) ];

    $self->{ deck } = [ 0 .. $size - 1 ];
=cut
    my $first = { val => 0 };
    $self->{ deck } = $first;
    for my $i (1 .. $size - 1) {
      my $card = { val => $i };
      $card->{ prev } = $self->{ deck };
      $self->{ deck }{ next } = $card;
      $self->{ deck } = $card;
     }
    $self->{ deck } = $first;
=cut

    bless $self, $class;
    return $self;
   }
}

#
# Note: For some reason, slurp is adding a line feed at the end of the
# input.
#
my $input_file = $ARGV[0] || 'input22.txt';
my $size = $ARGV[1] || 10007;

my $deck = Deck->new( $input_file, $size );

for my $inst (@{ $deck->{ inst } }) {
  $deck->shuffle( $inst );
 }

if ($size == 10007) {
  print "The position of card 2019 is ", $deck->pos( 2019 ), "\n";
 }
 
exit;
