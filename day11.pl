#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Grid;

  sub color {
    my ($self) = shift;
    my ($x, $y) = @_ ? @_ : ( $self->{ x }, $self->{ y } );

    my $coord = "$x,$y";

    return $self->{ color }{ $coord } || 0;
   }

  sub display {
    my ($self) = @_;

    my ($max_x, $min_x, $max_y, $min_y) = (0, 0, 0, 0);

    for my $coord (keys %{ $self->{ color } }) {
      my ($x, $y) = split /,/, $coord;
      $max_x = $x if ($max_x < $x);
      $min_x = $x if ($min_x > $x);
      $max_y = $y if ($max_y < $y);
      $min_y = $y if ($min_y > $y);
     }

    my $y = $max_y;
    while ($y >= $min_y) {
      for my $x ($min_x .. $max_x) {
        print ($self->color( $x, $y ) ? '*' : ' ');
        $x++;
       }
      print "\n";
      $y--;
     }

   }

  sub move {
    my ($self, $turn) = @_;

    if ($self->{ dir } eq '^') {
      $self->{ dir } = $turn ? '>' : '<';
      $self->{ x } += $turn ? 1 : -1;
     }
    elsif ($self->{ dir } eq 'v') {
      $self->{ dir } = $turn ? '<' : '>';
      $self->{ x } += $turn ? -1 : 1;
     }
    elsif ($self->{ dir } eq '<') {
      $self->{ dir } = $turn ? '^' : 'v';
      $self->{ y } += $turn ? 1 : -1;
     }
    elsif ($self->{ dir } eq '>') {
      $self->{ dir } = $turn ? 'v' : '^';
      $self->{ y } += $turn ? -1 : 1;
     }

    return $self;
   }

  sub paint {
    my ($self, $color) = @_;

    my $coord = "$self->{ x },$self->{ y }";

    $self->{ color }{ $coord } = $color;

    return $self;
   }

  sub new {
    my ($class) = @_;

    my $self = {
      x => 0,
      y => 0,
      dir => '^',
      paint => $ARGV[1] || 0,
      color => {},
    };

   bless $self, $class;

   return $self;
  }
}

{ package GAProgram;

  sub proc_output {
    my ($self) = @_;
 
    # First time through - nothing to process yet
    if (!$self->{ grid }) {
      $self->{ grid } = Grid->new();
      return;
     }

    die "Illegal output" unless (@{ $self->{ output } } == 2);
    my ($paint, $turn) = @{ $self->{ output } };
    $self->{ output } = [];

    if ($self->{ grid }->color() != $paint) {
      $self->{ grid }->paint( $paint );
     }

    $self->{ grid }->move( $turn );
    $self->{ input } = [ $self->{ grid }->color() ];

    return;
   }

  sub proc_1_2 {
    my ($self, $opcode) = @_;

    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ];
    $input1 += $self->{ rel } if ($modes % 10 == 2);
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10 == 1);
    $input1 ||= 0;
    $modes = int( $modes / 10 );

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    $input2 += $self->{ rel } if ($modes % 10 == 2);
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10 == 1);
    $input2 ||= 0;
    $modes = int( $modes / 10 );

    my $output = $self->{ code }[ $self->{ pos } + 3 ];
    $output += $self->{ rel } if ($modes % 10 == 2);

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
    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    # Input - no immediate mode
    my $addr = $self->{ code }[ $self->{ pos } + 1 ];
    $addr += $self->{ rel } if ($modes % 10 == 2);
    die "Illegal mode for opcode 3 at $self->{ pos }" if ($modes % 10 == 1);

    $self->proc_output();

    $self->{ code }[ $addr ] = shift @{ $self->{ input } };
    $self->{ pos } += 2;

    return 1;
   }

  sub proc_4 {
    my ($self) = @_;
    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $output = $self->{ code }[ $self->{ pos } + 1 ];
    $output += $self->{ rel } if ($modes % 10 == 2);
    $output = $self->{ code }[ $output ] unless ($modes % 10 == 1);

    push @{ $self->{ output } }, $output;

    $self->{ pos } += 2;

    return 1;
   }

  sub proc_5_6 {
    my ($self, $opcode) = @_;

    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input1 = $self->{ code }[ $self->{ pos } + 1 ] || 0;
    $input1 += $self->{ rel } if ($modes % 10 == 2);
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10 == 1);
    $modes = int( $modes / 10 );
    $input1 ||= 0;

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ] || 0;
    $input2 += $self->{ rel } if ($modes % 10 == 2);
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10 == 1);
    $input2 ||= 0;

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
    $input1 += $self->{ rel } if ($modes % 10 == 2);
    $input1 = $self->{ code }[ $input1 ] unless ($modes % 10 == 1);
    $modes = int( $modes / 10 );

    my $input2 = $self->{ code }[ $self->{ pos } + 2 ];
    $input2 += $self->{ rel } if ($modes % 10 == 2);
    $input2 = $self->{ code }[ $input2 ] unless ($modes % 10 == 1);
    $modes = int( $modes / 10 );

    my $output = $self->{ code }[ $self->{ pos } + 3 ];
    $output += $self->{ rel } if ($modes % 10 == 2);

    $self->{ code }[ $output ] = (($opcode == 7 && $input1 < $input2)
		|| ($opcode == 8 && $input1 == $input2)) ? 1 : 0;
    $self->{ pos } += 4;

    return 1;
   }

  sub proc_9 {
    my ($self) = @_;
    my $modes = int( $self->{ code }[ $self->{ pos } ] / 100 );

    my $input = $self->{ code }[ $self->{ pos } + 1 ];
    $input += $self->{ rel } if ($modes % 10 == 2);
    $input = $self->{ code }[ $input ] unless ($modes % 10 == 1);

    $self->{ rel } += $input;
    $self->{ pos } += 2;

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
    return $self->proc_9() if ($opcode == 9);

    die "Illegal opcode found: $opcode at $self->{ pos }";
   }

  sub init {
    my ($self) = @_;

    $self->{ pos } = 0;
    $self->{ rel } = 0;
    $self->{ output } = [];

    # Make a copy of the original program values
    @{ $self->{ code } } = @{ $self->{ init } };

    $self->{ grid } = undef;

    return $self;
   }

  sub run {
    my ($self, @input) = @_;
    $self->{ input } = [ @input ];
    while ($self->step()) {};
    return $self->{ output };
   }

  sub new {
    my ($class) = shift;
    my ($input_file) = @_;
    my $self = {};
    bless $self, $class;

    $self->{ init } = [ split /,/, Path::Tiny::path( $input_file )->slurp_utf8() ];
    $self->init();

    return $self;
   }
}

my $input_file = $ARGV[0] || 'input11.txt';

my $program = GAProgram->new( $input_file );

my $output = $program->run( $ARGV[1] || 0 );

print "There were ", scalar keys %{ $program->{ grid }{ color } }, " panels painted\n";

$program->{ grid }->display();

exit;
