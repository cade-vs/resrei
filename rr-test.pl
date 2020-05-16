#!/usr/bin/perl
##############################################################################
##
##  RESREI calendar remainder todo
##  2019-202 (c) Vladi Belperchinov-Shabanski "Cade"
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
  repeat yearly
  repeat daily
  
  on jun 12th at 11
  on 2021 march 1st

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
                
my @AC_WORDS = ( qw[ in on at next repeat noon day days year years yearly month months ], keys %WEEK_DAYS_LONG, keys %MONTHS_LONG );
                
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
  print Dumper( $repeat ) . "\n";
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
  
  my $now = time();
  my $ts = $now;
  my $tr;
  
  while( @$ta )
    {
    $_ = shift @$ta;
    if( /^in/ )
      {
      $ts = time() + parse_time_in( $ta );
      next;
      }
    elsif( /^on/ )
      {
      $ts = parse_time_on( $ta, $now );
      my $tss = $ts > 0 ? scalar localtime $ts : 'n/a';
      die "cannot set time in the past [$tss]\n" if $ts > 0 and $ts < $now;
      die "invalid date/time\n" if $ts < $now;
      next;
      }
    elsif( /^next/ )
      {
      $ts = parse_time_next( $ta, $now );
      next;
      }
    elsif( /^tom(orrow)?$/ )
      {
      $ts = utime_add_ymd( $now, 0, 0, 1 );
      }
    elsif( /^repeat/ )
      {
      $tr = parse_time_repeat( $ta );
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

sub parse_time_repeat
{
  my $ta = shift;
  
  my $tr = {};

  while( @$ta )
    {
    $_ = shift @$ta;
    $a = 0;

print STDERR "repeat: [$_]\n";
    
    if( /^(\d+|a)$/ )
      {
      $a = $1 eq 'a' ? 1 : $1;
      $_ = lc shift @$ta;
      }

    if( /^every/ )
      {
      next;
      }
    if( /^(daily|monthly|yearly)/ )
      {
      my $type = uc substr( $1, 0, 1 );

      my $tt;
      $tt +=     1 * 24 * 60 * 60 if $type eq 'D'; # dayly
      $tr->{ 'SECONDS' } += $tt;

      $tr->{ 'MONTHS'  } += 1 if $type eq 'M'; # months
      $tr->{ 'YEARS'   } += 1 if $type eq 'Y';  # years
      next;
      }
    elsif( /^(\d*)(h(ours?|rs?)?|d(ays?)?|w(eeks?|wks?)?|mo(n|nths?)?|y(ears?|rs?)?)$/ ) # hours hour hrs hr h 
      {
      my $type = uc substr( $2, 0, 1 );
      my $add = $1 || $a;

      $add = 1 unless $add > 0;

      my $tt;
      $tt +=          $add * 60 * 60 if $type eq 'H'; # hours
      $tt +=     $add * 24 * 60 * 60 if $type eq 'D'; # days
      $tt += $add * 7 * 24 * 60 * 60 if $type eq 'W'; # weeks
      
      $tr->{ 'SECONDS' } += $tt;

      $tr->{ 'MONTHS'  } += $add if $type eq 'M'; # months
      $tr->{ 'YEARS'   } += $add if $type eq 'Y';  # years
      next;
      }
    else
      {
      unshift @$ta, $_;
      return $tr;
      }  
    }
  
  return $tr;
}

sub parse_time_on
{
  my $ta  = shift;
  my $now = shift;
  
  my $day;
  my $mon;
  my $year;
  
  my $a;
  
  while( @$ta )
    {
    $_ = lc shift @$ta;

    if( /^(\d\d\d\d)$/ )
      {
      $year = $1;
      next;
      }
    elsif( /^(\d+)(st|nd)?$/ )
      {
      $day = $1;
      next;
      }
    elsif( exists $MONTHS{ $_ } )
      {
      $mon = $MONTHS{ $_ };
      next;
      }
    elsif( /^(\d\d\d\d)[\.\/\-](\d\d?)[\.\/\-](\d\d?)$/ )
      {
      my ( $year, $mon, $day ) = ( $1, $2, $3 );
      next;
      }
    else
      {
      unshift @$ta, $_;
      last;
      }  
    }

#  print STDERR "DEBUG: *on* year [$year] month [$mon] day [$day]\n";

  my ( $yc ) = utime_to_ymdhms( $now );
  return 0 if $year > 0 and $year < $yc;
  return 0 if $mon  > 0 and $mon  >  12;

  # try to figure the date
  if( $year > 0 and $mon > 0 and $day > 0 )
    {
    return utime_from_ymdhms( $year, $mon, $day );
    }
  elsif( $year > 0 and $mon > 0 )
    {
    return utime_from_ymdhms( $year, $mon, 1 );
    }
  elsif( $mon > 0 and $day > 0 )
    {
    return 0 if $day > get_year_month_days( $yc, $mon );
    my $uc = utime_from_ymdhms( $yc, $mon, $day );
    if( $now > $uc )
      {
      return 0 if $day > get_year_month_days( $yc + 1, $mon );
      return utime_from_ymdhms( $yc + 1, $mon, $day );
      }
    else
      {
      return $uc;
      }  
    }
  elsif( $mon > 0 )  
    {
    my $uc = utime_from_ymdhms( $yc, $mon, 1 );
    return $now > $uc ? utime_from_ymdhms( $yc + 1, $mon, 1 ) : $uc;
    }
  elsif( $day > 0 )  
    {
    my ( $yc, $mc ) = utime_to_ymdhms( $now );
    return 0 if $day > get_year_month_days( $yc, $mc );
    my $uc = utime_from_ymdhms( $yc, $mc, $day );
    if( $now > $uc )
      {
      if( $mc == 12 )
        {
        return 0 if $day > get_year_month_days( $yc + 1, 1 );
        return utime_from_ymdhms( $yc + 1, 1, $day )
        }
      else
        {
        return 0 if $day > get_year_month_days( $yc, $mc + 1 );
        return utime_from_ymdhms( $yc, $mc + 1, $day )
        }  
      }
    else
      {
      return $uc;
      }  
    }
  elsif( $year > 0 )  
    {
    return utime_from_ymdhms( $year, 1, 1 );
    }

  die "invalid timespec at *on* year [$year] month [$mon] day [$day]\n";
}

sub parse_time_in
{
  my $ta = shift;
  
  my $tt;

  my $a;
  while( @$ta )
    {
    $_ = lc shift @$ta;
    $a = 0;
    
    if( /^(\d+|a)$/ )
      {
      $a = $1 eq 'a' ? 1 : $1;
      $_ = lc shift @$ta;
      }
    
    if( /^(\d*)(h(ours?|rs?)?|d(ays?)?|w(eeks?|wks?)?|mo(n|nths?)?|y(ears?|rs?)?)$/ ) # hours hour hrs hr h 
      {
      my $type = uc substr( $2, 0, 1 );
      my $add = $1 || $a;
      
      $tt +=          $add * 60 * 60 if $type eq 'H'; # hours
      $tt +=     $add * 24 * 60 * 60 if $type eq 'D'; # days
      $tt += $add * 7 * 24 * 60 * 60 if $type eq 'W'; # weeks

      $tt = utime_add_ymd( $tt, 0, $add, 0 ) if $type eq 'M'; # months
      $tt = utime_add_ymd( $tt, $add, 0, 0 ) if $type eq 'Y';  # years
      next;
      }
    elsif( /^(\d*)(m(in(utes?)?)?)$/ ) # minutes minute min m
      {
      my $add = $1 || $a;

      $tt += $add * 60;
      next;
      }
    elsif( /^(\d*)(s(ec(ond)?s?)?)$/ ) # seconds second secs sec s
      {
      my $add = $1 || $a;

      $tt += $add;
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

# TODO: next month 11th
sub parse_time_next
{
  my $ta  = shift;
  my $now = shift;
  
  my $tt;

  while( @$ta )
    {
    $_ = shift @$ta;
    if( my $day = $WEEK_DAYS{ lc $_ } )
      {
      my $nod = utime_get_dow( $now );
      
      my $diffd = $day > $nod ? $day - $nod : $day + 7 - $nod;
      
      return utime_goto_midnight( $now ) + $diffd * 24 * 60 * 60;
      }
    elsif( my $mon = $MONTHS{ lc $_ } )
      {
      my $nom = utime_get_moy( $now );
      
      my $diffm = $mon > $nom ? $mon - $nom : $mon + 12 - $nom;
      
      return utime_goto_first_dom( utime_add_ymd( utime_goto_midnight( $now ), 0, $diffm, 0 ) );
      }
    elsif( /^year$/i )
      {
      return utime_goto_first_doy( utime_add_ymd( $now, 1, 0, 0 ) );
      }
    elsif( /^month$/i )
      {
      return utime_goto_first_dom( utime_add_ymd( $now, 0, 1, 0 ) );
      }
    elsif( /^day$/i )
      {
      return utime_add_ymd( $now, 0, 0, 1 );
      }
    else
      {
      die "invalid timespec at *next* [$_]\n";
      }  
    }
  
  return $tt;
}

# TODO: am/pm?
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
