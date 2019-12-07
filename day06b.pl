#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package GAProgram;

  sub proc_1_2 {
    my ($self, $opcode) = @_;

    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10);
    $modes = int( $modes / 10 );

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10);

    my $output = $self->{ code }[ $self->{ pos } + 3 ];

    if ($opcode == 1) {
      $self->{ code }[ $output ] = $input1 + $input2;
     }
    else {
      $self->{ code }[ $output ] = $input1 * $input2;
     }
    $self->{ pos } += 4;

    return 1;
   }

  sub proc_3 {
    my ($self) = @_;
    my $addr = $self->{ code }[ $self->{ pos } + 1 ];

    # See if we are waiting on input
    return 0 unless @{ $self->{ input } };

    $self->{ code }[ $addr ] = shift @{ $self->{ input } };
    $self->{ pos } += 2;

    return 1;
   }

  sub proc_4 {
    my ($self) = @_;
    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $output = $self->{ code }[ $self->{ pos } + 1 ];
    $output = $self->{ code }[ $output ] unless ($modes % 10);

    $self->{ output } = $output;

    $self->{ pos } += 2;

    return 1;
   }

  sub proc_5_6 {
    my ($self, $opcode) = @_;

    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10);
    $modes = int( $modes / 10 );

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10);

    if (($opcode == 5 && $input1) || ($opcode == 6 && !$input1)) {
      $self->{ pos } = $input2;
     }
    else {
      $self->{ pos } += 3;
     }

    return 1;
   }

  sub proc_7_8 {
    my ($self, $opcode) = @_;

    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10);
    $modes = int( $modes / 10 );

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10);

    my $output = $self->{ code }[ $self->{ pos } + 3 ];

    $self->{ code }[ $output ] = (($opcode == 7 && $input1 < $input2)
		|| ($opcode == 8 && $input1 == $input2)) ? 1 : 0;
    $self->{ pos } += 4;

    return 1;
   }

  sub step {
    my ($self) = @_;
    my $opcode = $self->{ code }[ $self->{ pos } ] % 100;
   
    if ($opcode == 99) {
      $self->{ complete } = 1;
      return 0;
     }
    return $self->proc_1_2( $opcode ) if ($opcode <= 2);
    return $self->proc_3() if ($opcode == 3);
    return $self->proc_4() if ($opcode == 4);
    return $self->proc_5_6( $opcode ) if ($opcode == 5 || $opcode == 6);
    return $self->proc_7_8( $opcode ) if ($opcode == 7 || $opcode == 8);

    die "Illegal opcode found: $opcode at $self->{ pos }";
   }

  sub init {
    my ($self) = @_;

    $self->{ input } = [];
    $self->{ complete } = 0;
    $self->{ pos } = 0;
    $self->{ output } = undef;

    # Make a copy of the original program values
    @{ $self->{ code } } = @{ $self->{ init } };

    return $self;
   }

  sub run {
    my ($self, @input) = @_;
    push @{ $self->{ input } }, @input;
    while ($self->step()) {};
    return $self->{ output };
   }

  sub new {
    my ($class, $code) = @_;
    my $self = {};
    bless $self, $class;

    $self->{ init } = $code;
    $self->init();

    return $self;
   }
}

sub not_in {
  my (@set) = @_;

  my %vals = ( 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0 );
  for my $s (@set) {
    $vals{ $s } = 1;
   }

  return sort map { $vals{ $_ } ? () : $_ } keys %vals;
 }

sub next_sequences {
  my (@seq) = @_;
  my @new_seq = ();
  for my $next (not_in( @seq )) {
    push @new_seq, [ @seq, $next ];
   }

  return @new_seq;
 }

sub get_sequences {
  my $seq = [ [5], [6], [7], [8], [9] ];

  while (@{ $seq->[0] } < 5) {
    my $next_seq = [];
    for my $s (@{ $seq }) {
      push @{ $next_seq }, next_sequences( @{ $s } );
     }
    $seq = $next_seq;
   }

  return $seq;
 }

my $input_file = $ARGV[0] || 'input06.txt';
my $code = [ split /,/, Path::Tiny::path( $input_file )->slurp_utf8() ];

my $program = 

my $sequences = get_sequences();
my $max_val = 0;

my $s = [ 9, 8, 7, 6, 5 ];

for my $s (@{ $sequences }) {
  # Create separate programs for each amplifier initially setting the phase
  my @amps = map { my $p = GAProgram->new( $code ); $p->{ input } = [ $s->[ $_ ] ]; $p } (0 .. 4);
# push @{ $amps->[0]{ input } }, 0;

  my $signal = 0;
  my $done = 0;
  while (!$done) {
    for my $i (0 .. 4) {
      $signal = $amps[$i]->run( $signal );
      $done = $amps[$i]->{ complete };
     }
   }

  if ($signal > $max_val) {
    $max_val = $signal;
   }
 }

print "The maximum signal is $max_val\n";

