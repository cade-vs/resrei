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
use Data::Tools::Time;

=pod

  in 2days 8hrs 11min 23sec
  next tue at 12:00
  next apr 1st
  next last tue of mar

  repeat every year|month|day
  repeat every 6hrs

=cut


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
  
  my $ts = time();
  my $tr = 0;
  
  while( @$ta )
    {
    $_ = shift @$ta;
    if( /^in/ )
      {
      $ts = time() + parse_time_in( $ta );
      next;
      }
    elsif( /^repeat/ )
      {
      $tr = parse_time_in( $ta );
      next;
      }
    else
      {
      die "invalid timespec at [$_]\n";
      }  
    }
  return $ts;
}

sub parse_time_in
{
  my $ta = shift;
  
  my $tt;

  while( @$ta )
    {
    $_ = shift @$ta;
    if( /^repeat/ )
      {
      }
    elsif( /^(\d+)d(ays?)?$/ )         # days day d
      {
      $tt += $1 * 24 * 60 * 60;
      next;
      }
      # TODO: months, years, weeks
#    elsif( /^(\d+)(h(ours?)?|hrs?)$/ ) # hours hour hrs hr h 
    elsif( /^(\d+)(h(ours?|rs?)?|d(ays?)?|w(eeks?|wks?)?|mo(n|nths?)?|y(ears?|rs?)?)$/ ) # hours hour hrs hr h 
      {
      my $type = uc substr( $2, 0, 1 );
      $tt +=          $1 * 60 * 60 if $type eq 'H'; # hours
      $tt +=     $1 * 24 * 60 * 60 if $type eq 'D'; # days
      $tt += $1 * 7 * 24 * 60 * 60 if $type eq 'W'; # weeks

      $tt = utime_add_ymd( $tt, 0, $1, 0 ) if $type eq 'M'; # months
      $tt = utime_add_ymd( $tt, $1, 0, 0 ) if $type eq 'Y'; # years
      next;
      }
    elsif( /^(\d+)(m(in(utes?)?)?)$/ ) # minutes minute min m
      {
      $tt += $1 * 60;
      next;
      }
    elsif( /^(\d+)(s(ec(ond)?s?)?)$/ ) # seconds second secs sec s
      {
      $tt += $1;
      next;
      }
    else
      {
      unshift @$ta, $_;
      return $tt;
      }  
    }
  
  return $tt;
}
