#!/usr/bin/perl
##############################################################################
##
##  RESREI calendar remainder todo
##  2019 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
use strict;
use Data::Dumper;
use Term::ReadLine::Tiny;
use Data::Tools::Time;

=pod

  in 2days 8hrs 11min 23sec
  in 2h
  in 1week
  in 2mo
  
  next tue at 12:00
  next apr 1st

  repeat every year|month|day    at 11:06
  repeat every 6hrs

=cut

my %WEEK_DAYS_SHORT = (
                
                mon => 1,
                tue => 2,
                wed => 3,
                thu => 4,
                fri => 5,
                sat => 6,
                sun => 7,
                
                );

my %WEEK_DAYS_LONG = (
                
                monday    => 1,
                tuesday   => 2,
                wednesday => 3,
                thursday  => 4,
                friday    => 5,
                saturday  => 6,
                sunday    => 7,
                
                );
                
my %WEEK_DAYS = ( %WEEK_DAYS_SHORT, %WEEK_DAYS_LONG );

my %MONTHS_SHORT = (
                
                jan =>  1,
                feb =>  2,
                mar =>  3,
                apr =>  4,
                may =>  5,
                jun =>  6,
                jul =>  7,
                aug =>  8,
                sep =>  9,
                oct => 10,
                nov => 11,
                dec => 12,
                
                );
                
my %MONTHS_LONG = (
                january   =>  1,
                february  =>  2,
                march     =>  3,
                april     =>  4,
                may       =>  5,
                june      =>  6,
                july      =>  7,
                august    =>  8,
                september =>  9,
                october   => 10,
                november  => 11,
                december  => 12,
                
                );

my %MONTHS = ( %MONTHS_SHORT, %MONTHS_LONG );
                
my @AC_WORDS = ( qw[ in on at next repeat noon ], keys %WEEK_DAYS_LONG, keys %MONTHS_LONG );
                
my $rl = Term::ReadLine::Tiny->new( "" );
$rl->autocomplete( \&autocomplete );
        
while(4)
  {
  my $line = $rl->readline( "resrei: " );
  last if $line =~ /^(q|x|quit|exit|zz)/;
  my @line = split /\s+/, $line;
  
  my ( $time, $repeat ) = parse_time( @line );
  print scalar localtime( time() ) . "\n";
  print scalar localtime( $time  ) . "\n";
  print $repeat . "\n";
  }


sub autocomplete
{
  my $rl   = shift;
  my $text = shift;
  
  return $text unless $text =~ /(\S+)$/;
  my $co = $1;

  my @rc = grep /^$co/, @AC_WORDS;

  return $text unless @rc;
  
  if( @rc == 1 )
    {
    $text .= substr( $rc[0], length( $co ) ) . ' ';
    }
  else
    {
    print "\n@rc\nresrei: $text";
    }  
  
  #print Dumper( \@_ );
  return $text;
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
    if( /^next/ )
      {
      $ts = parse_time_next( $ta );
      }
    elsif( /^repeat/ )
      {
      $tr = parse_time_in( $ta );
      next;
      }
    elsif( /^at/ )
      {
      my $at = parse_time_at( $ta );
      my ( $tsd ) = utime_split_to_utt( $ts );
      $ts = utime_join_utt( $tsd, $at );
      next;
      }
    else
      {
      die "invalid timespec at [$_]\n";
      }  
    }
  return ( $ts, $tr );
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
    elsif( /^(\d+)(h(ours?|rs?)?|d(ays?)?|w(eeks?|wks?)?|mo(n|nths?)?|y(ears?|rs?)?)$/ ) # hours hour hrs hr h 
      {
      my $type = uc substr( $2, 0, 1 );
      $tt +=          $1 * 60 * 60 if $type eq 'H'; # hours
      $tt +=     $1 * 24 * 60 * 60 if $type eq 'D'; # days
      $tt += $1 * 7 * 24 * 60 * 60 if $type eq 'W'; # weeks

      $tt = utime_add_ymd( $tt, 0, $1, 0 ) if $type eq 'M'; # months
      $tt = utime_add_ymd( $tt, $1, 0, 0 ) if $type eq 'Y';  # years
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


sub parse_time_next
{
  my $ta = shift;
  
  my $tt;

  while( @$ta )
    {
    $_ = shift @$ta;
    if( my $day = $WEEK_DAYS{ lc $_ } )
      {
      my $now = time();
      
      my $nod = utime_get_dow( $now );
      
      my $diffd = $day > $nod ? $day - $nod : $day + 7 - $nod;
      
      return utime_goto_midnight( $now ) + $diffd * 24 * 60 * 60;
      }
    elsif( my $mon = $MONTHS{ lc $_ } )
      {
      my $now = time();
      
      my $nom = utime_get_moy( $now );
      
      my $diffm = $mon > $nom ? $mon - $nom : $mon + 12 - $nom;
      
      return utime_goto_first_dom( utime_add_ymd( utime_goto_midnight( $now ), 0, $diffm, 0 ) );
      }
    elsif( /^year$/i )
      {
      my $now = time();
      
      return utime_goto_first_doy( utime_add_ymd( $now, 1, 0, 0 ) );
      }
    else
      {
      die "invalid timespec at *next* [$_]\n";
      }  
    }
  
  return $tt;
}

sub parse_time_at
{
  my $ta = shift;
  
  my $tt;

  while( @$ta )
    {
    $_ = shift @$ta;
    if( $_ =~ /(\d+)(:(\d+)?(:(\d+))?)?/ )
      {
      $tt = $1 * 60 * 60 + $3 * 60 + $5;
      }
    elsif( lc $_ eq 'noon' )
      {
      $tt = 12 * 60 * 60;
      }
    else
      {
      die "invalid timespec at *next* [$_]\n";
      }  
    }
  
  return $tt;
}
