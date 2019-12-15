#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;
use POSIX qw( ceil );

{ package Reaction;

  sub new {
    my ($class, $input) = @_;

    my $self = {
      out => {},
      in => {},
    };

    my ($i, $q, $o) = ($input =~ /^(.*?)\s*=>\s*(\d+)\s(.*)$/);

    for my $chem (split /,\s*/, $i) {
      $chem =~ /^(\d+)\s(.*)$/;
      $self->{ in }{ $2 } = $1;
     }

    $self->{ out } = $o;
    $self->{ quant } = $q;

    bless $self, $class;

    return $self;
   }
}

{ package Nanofactory;

  sub make {
    my ($self, $need) = @_;

    my $done = 1;
    for my $chem (keys %{ $need }) {
      next if ($chem eq 'ORE');
      next if ($need->{ $chem } <= 0);

      $done = 0;
      my $react = $self->{ react }[$self->{ out }{ $chem }];
      my $num_react = POSIX::ceil( $need->{ $chem } / $react->{ quant } );
      $need->{ $chem } -= $react->{ quant } * $num_react;
      for my $inp (keys %{ $react->{ in } }) {
        $need->{ $inp } += $react->{ in }{ $inp } * $num_react;
       }
     }

    return $done ? $need : $self->make( $need );
   }

  sub new {
    my ($class, $input_file) = @_;

    my $self = {
      react => [],
      out => {},
    };

   for (Path::Tiny::path( $input_file )->lines_utf8( { chomp => 1 } )) {
     my $react = Reaction->new( $_ );
     my $out = $react->{ out };
     die "Multiple reactions create $out" if ($self->{ out }{ $out });
     $self->{ out }{ $out } = @{ $self->{ react } };
     push @{ $self->{ react } }, $react;
    }

   bless $self, $class;

   return $self;
  }
}

my $input_file = $ARGV[0] || 'input14.txt';

my $fact = Nanofactory->new( $input_file );
my $amount = $ARGV[1] || 1;

my $make = $fact->make( { FUEL => 1 } );
if ($amount == 1) {
  # Part A
  my $make = $fact->make( { FUEL => $amount } );
  print "It takes ", $make->{ ORE }, " ORE to make fuel\n";
 }
else {
  # Part B
  my $one_fuel = $make->{ ORE };
  my $fuel = int( $amount / $one_fuel );
  my $ore;
  do {
    $make = $fact->make( { FUEL => $fuel } );
    $ore = $amount - $make->{ ORE };
    $fuel += int( $ore / $one_fuel );
  } while ($ore >= $one_fuel);

  # We are within one fuel unit - keep trying
  while ($fact->make( { FUEL => $fuel + 1 } )->{ ORE } < $amount) {
    $fuel++;
   }
  print "You can make $fuel with $amount ORE\n";
 }
exit;
