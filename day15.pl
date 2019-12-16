#!/usr/bin/env perl
#
use strict;
use warnings;
use utf8;

use Path::Tiny;

{ package Point;

  sub new {
    my ($class, $x, $y, $route, $value) = @_;

    my $self = {
      x => $x,
      y => $y,
      route => $value ? $route : [],
      value => $value || -1,
      minutes => 0,
    };

   bless $self, $class;

   return $self;
  }
}

{ package Grid;

  my $dirs = { 1 => [ 0, 1 ], 2 => [ 0, -1 ], 3 => [ -1, 0 ], 4 => [ 1, 0 ] };

  sub display {
    my ($self) = @_;

    my ($max_x, $min_x, $max_y, $min_y) = (0, 0, 0, 0);

    for my $coord (keys %{ $self->{ grid } }) {
      my ($x, $y) = split /,/, $coord;
      $max_x = $x if ($max_x < $x);
      $min_x = $x if ($min_x > $x);
      $max_y = $y if ($max_y < $y);
      $min_y = $y if ($min_y > $y);
     }

    my $y = $max_y;
    while ($y >= $min_y) {
      for my $x ($min_x .. $max_x) {
        my $v = $self->{ grid }{ "$x,$y" }{ value };
        if ("$x,$y" eq "0,0") {
          print "X";
         }         
        else {
          print ($v ? $v > 0 ? $v : '*' : '?');
         }
        $x++;
       }
      print "\n";
      $y--;
     }
    print "\n";
   }

  sub explore {
    my ($self) = @_;

    $self->{ grid }{ "0,0" } = Point->new( 0, 0, [], 1 );
    my $points = [ $self->{ grid }{ "0,0" } ];

    while (@{ $points }) {
      my $point = shift @{ $points };
      # $self->display();
      for my $dir (keys %{ $dirs }) {
        my ($x, $y) = ($point->{ x } + $dirs->{ $dir }[0], $point->{ y } + $dirs->{ $dir }[1]);
        my $pos = "$x,$y";
        next if ($self->{ grid }{ $pos }{ value });
        my $next_route = [ @{ $point->{ route } }, $dir ];
        my $output = $self->run( $next_route );
        $self->{ grid }{ $pos } = Point->new( $x, $y, $next_route, $output );
        next if ($output == 0);
        if ($output == 2) {
          $self->{ oxygen } = $self->{ grid }{ $pos };
         }
        push (@{ $points }, $self->{ grid }{ $pos });
       }
     }

$self->display();

    return scalar @{ $self->{ oxygen }{ route } };
   }

  sub fill {
    my ($self) = @_;

    my $pos = "$self->{ oxygen }{ x },$self->{ oxygen }{ y }";

    my $points = [ $self->{ grid }{ $pos } ];

    while (@{ $points }) {
      my $point = shift @{ $points };
      my $minutes = $point->{ minutes } + 1;
      for my $dir (keys %{ $dirs }) {
        my ($x, $y) = ($point->{ x } + $dirs->{ $dir }[0], $point->{ y } + $dirs->{ $dir }[1]);
        my $pos = "$x,$y";
        next unless ($self->{ grid }{ $pos }{ value } == 1);
        $self->{ grid }{ $pos }{ value } = 2;
        $self->{ grid }{ $pos }{ minutes } = $minutes;
        $self->{ minutes } = $minutes if ($self->{ minutes } < $minutes);
        push (@{ $points }, $self->{ grid }{ $pos });
       }
     }

$self->display();

    return $self->{ minutes };
   }

  sub run {
    my ($self, $path) = @_;

    $self->{ program }->init();
    my $output;
    for my $dir (@{ $path }) {
      $output = $self->{ program }->run( $dir );
     }

    return pop @{ $output };
   }

  sub new {
    my ($class, $program) = @_;

    my $self = {
      program => $program,
      grid => {},
      minutes => 0,
    };

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
    die "No input for opcode 3 at $self->{ pos }" unless (@{ $self->{ input } });

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

    # This program should return the output value and pause for more input

    return 0;
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

my $input_file = 'input15.txt';

my $program = GAProgram->new( $input_file );

my $grid = Grid->new( $program );

print "It took ", $grid->explore(), " moves to find the droid.\n";

print "It took ", $grid->fill(), " to fill the region with oxygen.\n";

exit;
