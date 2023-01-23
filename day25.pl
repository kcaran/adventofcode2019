#!/usr/bin/env perl
#
# Use inheritance to override IntCode functions!
#

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Storable 'dclone';
$| = 1;

#Term::ReadKey::ReadMode( 'cbreak' );

use IntCode;

my @input;
my @items = (
	'festive hat',
	'food ration',
	'spool of cat6',
	'fuel cell',
	'hologram',
	'space heater',
	'space law space brochure',
	'tambourine',
);
my $id = 1;

{ package MyProgram;

  use parent 'IntCode';

  sub inv {
    my ($id) = @_;

    my $bit = 0;
    my @inv;
    while ($id) {
      if ($id & (1 << $bit)) {
        push @inv, $items[$bit];
        $id ^= (1 << $bit);
       }
      $bit++;
     }

    return (@inv);
   }

  sub read_input {
    my ($self) = @_;

    unless (@{ $self->{ input } }) {
      my $next = shift @input;
      if (!$next && $id <= 2**8) {
        my @inv = inv( $id );
        my $cmds = join( '', map { "take $_\n" } @inv );
        $cmds .= "south\n";
        $cmds .= join( '', map { "drop $_\n" } @inv );
        @input = split( '', $cmds );
        $next = shift @input;
        $id++;
       }

      my $input_key = $next || Term::ReadKey::ReadKey(0);
      $self->{ echo } .= $input_key;
      $self->{ input } = [ ord( $input_key ) ];
      print $input_key;
      Path::Tiny::path( 'input25.txt' )->append_utf8( $input_key ) unless ($next);
     }

    return $self;
   }

  sub write_output {
    my ($self) = @_;

    while (my $out = shift @{ $self->{ output } }) {
      print chr( $out );
     }

    return;
   }

};

my $comp = MyProgram->new( 'prog25.txt' );
@input = split( '', Path::Tiny::path( 'input25.txt' )->slurp_utf8() );
$comp->run();

Term::ReadKey::ReadMode( 'normal' );

exit;
