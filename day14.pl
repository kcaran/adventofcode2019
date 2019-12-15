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
      ore => 0,
      left => {},
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

my $make = $fact->make( { FUEL => 1 } );
print "It takes ", $make->{ ORE }, " ORE to make fuel\n";

exit;
