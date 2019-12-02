#!/usr/bin/env perl
#
# $Id: $
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package GAProgram;

  sub step {
    my ($self) = @_;
    my $opcode = $self->{ code }[ $self->{ pos } ];
    return 0 if ($opcode == 99);
    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    my $output = $self->{ code }[ $self->{ pos } + 3 ];
    my $newval;
    if ($opcode == 1) {
      $newval = $self->{ code }[ $input1 ] + $self->{ code }[ $input2 ];
     }
    elsif ($opcode == 2) {
      $newval = $self->{ code }[ $input1 ] * $self->{ code }[ $input2 ];
     }
    else {
      die "Illegal opcode $opcode at pos $self->{ pos }";
     }

    $self->{ code }[ $output ] = $newval;
    $self->{ pos } += 4;

    return 1;
   }

  sub run {
    my ($self) = @_;
    while ($self->step()) {};
    return $self;
   }

  sub new {
    my $class = shift;
    my ($input_file) = @_;
    my $self;

    $self->{ pos } = 0;
    $self->{ code } = [ split /,/, Path::Tiny::path( $input_file )->slurp_utf8() ];
    bless $self, $class;
    return $self;
   }
}

my $input_file = $ARGV[0] || 'input02.txt';

my $program = GAProgram->new( $input_file );

$program->{ code }[1] = 12;
$program->{ code }[2] = 2;

$program->run();

print "The value at position 0 is $program->{ code }[0]\n";
