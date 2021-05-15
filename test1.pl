#!/usr/bin/perl
use strict;
use Time::HiRes;
use Data::Tools;
use Data::Dumper;
use Storable qw( nfreeze thaw );

print( Time::HiRes::time(), "\n" );
print( Time::HiRes::time(), "\n" );

my $h = { 
        'NAME'   => 'asdas dasd asd asd asd as das asd asd asd as dasd sa',
        'DES'    => 'qw eqwe qwe qw eqwe  q we qw e qw e qwe qw eq e qweqw qe qwe qw eqwe qwe qwe',
        'REPEAT' => ' 1month 2 years 3 days etc',
        'NEXT'   => ' 1month 2 years 3 days etc',
        'BEGIN'  => ' 1month 2 years 3 days etc',
        'END'    => ' 1month 2 years 3 days etc',
        };


for( 1 .. 10000 )
  {
  file_save( "data/$_", nfreeze( $h ) );
  file_save( "data/$_.txt", Dumper( $h ) );
  }

for( 1 .. 10000 )
  {
  my $hh = thaw( file_load( "data/$_" ) );
  }



