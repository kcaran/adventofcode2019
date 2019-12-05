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
    my $input = $ARGV[1] || 1;
    my $addr = $self->{ code }[ $self->{ pos } + 1 ];
    $self->{ code }[ $addr ] = $input;
    $self->{ pos } += 2;

    return 1;
   }

  sub proc_4 {
    my ($self) = @_;
    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10);

    print "$input1\n"; 
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
   
    return 0 if ($opcode == 99);
    return $self->proc_1_2( $opcode ) if ($opcode <= 2);
    return $self->proc_3() if ($opcode == 3);
    return $self->proc_4() if ($opcode == 4);
    return $self->proc_5_6( $opcode ) if ($opcode == 5 || $opcode == 6);
    return $self->proc_7_8( $opcode ) if ($opcode == 7 || $opcode == 8);

    die "Illegal opcode found: $opcode at $self->{ pos }";
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

my $input_file = $ARGV[0] || 'input05.txt';

my $program = GAProgram->new( $input_file );
$program->run();

