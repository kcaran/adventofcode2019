#!/usr/bin/env perl
#
# Size of map - 48 wide (including \n) x 65  = 3120
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Grid;

  sub display {
    my ($self) = @_;

    for my $y (0 .. @{ $self->{ grid } } - 1) {
      for my $x (0 .. @{ $self->{ grid }[$y] } - 1) {
        print $self->{ grid }[$y][$x];
        if ($self->{ grid }[$y][$x] eq '#' && $x > 0 && $y > 0
          && $self->{ grid }[$y-1][$x] eq '#'
          && ($self->{ grid }[$y+1][$x] || '') eq '#'
          && $self->{ grid }[$y][$x-1] eq '#'
          && ($self->{ grid }[$y][$x+1] || '') eq '#') {
          $self->{ align } += $y * $x;
         }      
       }
      print "\n";
     }

    return $self;
   }

  sub new {
    my ($class, $input) = @_;

    my $self = {
      grid => [],
      align => 0,
    };

   my ($x, $y) = (0, 0);
   for my $char (@{ $input }) {
     if ($char == 10) {
       $x = 0;
       $y++;
       next;
      }

     $self->{ grid }[$y][$x] = chr( $char );
     $x++;
    }

   bless $self, $class;

   return $self;
  }
}

{ package GAProgram;

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

    $self->{ code }[ $addr ] = shift @{ $self->{ input } };
    $self->{ pos } += 2;

    # We shouldn't have any output yet
    $self->{ output } = [];

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

    print $output < 128 ? chr( $output ) : "Dust: $output\n";

    if ( 0 && @{ $self->{ output } } > 1 && $self->{ output }[-1] == 10 && $self->{ output }[-2] == 10) {
      pop @{ $self->{ output } };
      pop @{ $self->{ output } };
      my $grid = Grid->new( $self->{ output } )->display();
      print "The alignment parameter is $grid->{ align }.\n";

      $self->{ output } = [];
     }

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

    return $self;
   }

  sub run {
    my ($self, $input) = @_;
    if ($input) {
      $self->{ code }[0] = 2;
      $self->{ input } = [ map { ord( $_ ) } split '', $input ];
     }
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

my $program = GAProgram->new( 'input17.txt' );

my $input;
my $input_file = $ARGV[0];

if ($input_file) {
  $input = Path::Tiny::path( $input_file )->slurp_utf8();
 }

my $output = $program->run( $input );

#my $grid = Grid->new( $output );

#$grid->display();

exit;
