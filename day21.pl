#!/usr/bin/env perl
#
# Use inheritance to override IntCode functions!
#
# part a:
# NOT C J
# NOT B T
# OR T J
# NOT A T
# OR T J
# AND D J
# WALK

use strict;
use warnings;
use utf8;

use Path::Tiny;
use IntCode;
use Term::ReadKey;

Term::ReadKey::ReadMode( 'cbreak' );

{ package MyProgram;

  use parent 'IntCode';

=cut
  sub read_input {
    my ($self) = @_;

    die "In program";

    return ($self);
   }
=cut
  sub write_output {
   my ($self) = @_;

   while (@{ $self->{ output } }) {
     my $output = shift @{ $self->{ output } };
     print $output < 128 ? chr( $output ) : "Dust: $output\n";
    }

   return $self;
  }
};

my $program = MyProgram->new( 'input21.txt' );

$program->run();

Term::ReadKey::ReadMode( 'normal' );

exit;
