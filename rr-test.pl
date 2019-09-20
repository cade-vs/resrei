#!/usr/bin/perl
##############################################################################
##
##  RESREI calendar reimder todo
##  2019 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
use strict;







while(4)
  {
  my $line = <STDIN>;
  my @line = split /\s+/, $line;
  
  my $time = parse_time( @line );
  print scalar localtime( time() ) . "\n";
  print scalar localtime( $time  ) . "\n";
  }




sub parse_time
{
  my $ta = [ @_ ];
  
  my $ti = { TS => time(), TR => 0 }; # time info, time stamp and time repeat
  
  while( @$ta )
    {
    $_ = shift @$ta;
    if( /^in/ )
      {
      parse_time_in( \@ti, $ti );
      next;
      }
    elsif( /^repeat/ )
      {
      parse_time_repeat( \@ti, $ti );
      next;
      }
    else
      {
      die "invalid timespec at [@$ta]\n";
      }  
    }

}

sub parse_time_in
{
  my $ta = shift;
  my $ti = shift;

  while( @$ta )
    {
    $_ = shift @$ta;
    if( /^repeat/ )
      {
      return parse_time_repeat( \@ti, $ti );
      }
    elsif( /(\d+)d(ays?)?/ )         # days day d
      {
      $ti->{ 'TS' } += $1 * 24 * 60 * 60;
      next;
      }
    elsif( /(\d+)(h(ours?)?|hrs?)/ ) # hours hour hrs hr h 
      {
      $ti->{ 'TS' } += $1 * 60 * 60;
      next;
      }
    elsif( /(\d+)(m(in(utes?)?)?)/ ) # minutes minute min m
      {
      $ti->{ 'TS' } += $1 * 60;
      next;
      }
    elsif( /(\d+)(s(ec(onds?)?)?|secs)/ ) # seconds second secs sec s
      {
      $ti->{ 'TS' } += $1;
      next;
      }
    else
      {
      die "invalid timespec at [@$ta]\n";
      }  
    }
}

sub parse_time_repeat
{
  my $ta = shift;
  my $ti = shift;
  
}

=pod

  in 2days 8hrs 11min 23sec
  next tue at 12:00
  next apr 1st
  next last tue of mar

  repeat every year|month|day
  repeat every 6hrs

=cut
