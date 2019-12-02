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

  sub init {
    my ($self) = @_;

    $self->{ pos } = 0;

    # Make a copy of the original program values
    @{ $self->{ code } } = @{ $self->{ init } };

    return $self;
   }

  sub run {
    my ($self) = @_;
    while ($self->step()) {};
    return $self;
   }

  sub new {
    my $class = shift;
    my ($input_file) = @_;
    my $self = {};
    bless $self, $class;

    $self->{ init } = [ split /,/, Path::Tiny::path( $input_file )->slurp_utf8() ];
    $self->init();

    return $self;
   }
}

my $input_file = $ARGV[0] || 'input02.txt';
my $desired = $ARGV[1] || 19690720;

my $program = GAProgram->new( $input_file );

for (my $noun = 0; $noun < 100; $noun++) {
  for (my $verb = 0; $verb < 100; $verb++) {
    $program->init();
    $program->{ code }[1] = $noun;
    $program->{ code }[2] = $verb;
    $program->run();
    if ($program->{ code }[0] == $desired) {
      my $value = $noun * 100 + $verb;
      print "The desired value of $desired is met with $value\n";
      exit;
     }
   }
 }

