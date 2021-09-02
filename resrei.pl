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
use POSIX;
use Data::Dumper;
use Time::HiRes;
use Term::ReadLine::Tiny;
use Data::Tools;
use Data::Tools::Time;
use Data::Stacker;

##############################################################################
=pod

TODO: limit clause for count: new in a week repeat weekly limit 4 times
TODO: limit clause for time:  new in a week repeat weekly limit until 4th dec
TODO: first/last: new on last sat of jun 2021
TODO: set 'near time' per event, default is now 30 days

=cut
##############################################################################

my $DEBUG;
my $HELP = <<END_OF_HELP;

usage: $0 <options> <command> <timespec> -- message

options:

  -h       -- print help
  -a dir   -- set data dir to hold resrei database (default is ~/.resrei)
  -p       -- allows date/time in the past
  -b       -- black & white mode, remove colors
  -d       -- increase debug level
  -y       -- assume YES to all questions (disables -n)
  -n       -- assume NO  to all questions (disables -y)
  -q       -- suppress non-urgent messages

commands:

  NEW <timespec>       -- create new event
  VIEW <ID>            -- show details for event <ID>
  <ID>...              -- (no command) show details for event <ID>... list
  DEL  <ID>...         -- delete given event <ID>... list
  MOVE <ID> <timespec> -- move event with <ID> to new time
  RENAME <ID> <name>   -- sets event <ID> name to <name>
  REPEAT <ID> <repeat> -- sets new repeat interval for <ID> event
  LIST                 -- list upcoming events
  LIST ALL             -- list all events
  LIST DELETED         -- list deleted events
  LIST OVERDUE         -- list overdue events only
  LIST ACTIVE          -- list active (targets in 7 days and overdue) events
  CHECK <ID>...        -- mark <ID>.. events as checked (i.e. seen/done)
  UNCHECK <ID>...      -- removed checked mark for <ID>... events

  commands have aliases:  LIST=L,     VIEW=V,  DELETE=DEL, RENAME=NAME, 
                          REPEAT=REP, CHECK=C, UNCHECK=U
       
  LIST cmd has aliases: ALL=L, DELETED=D, OVERDUE=O, ACTIVE=A

timespec specification examples:

  specify day in the future:
  
    in 2days 8hrs 11min 23sec
    in 2h
    in 1week
    in 2mo

  specify exact date (and time):

    on jun 12th at 4:30 pm
    on 2021 march 1st at noon

  specify exact time:
  
    at 11
    at 2:30 pm

  specify day and time in the future:
  
    next tue at 12:00
    next apr 1st

  specify repeat period:

    repeat every year|month|day  at 11:06
    repeat every 6hrs
    repeat yearly
    repeat daily

more examples:

    resrei new on next sat at 11:30 repeat weekly
    resrei new in a week and 1 day at 11pm -- evening test

END_OF_HELP

my %__PC_COLORS =
                   (
                      # foregrounds 
                      'fk' => '0;30', #blacK
                      'fr' => '0;31', #Red
                      'fg' => '0;32', #Green
                      'fy' => '0;33', #Yellow
                      'fb' => '0;34', #Blue
                      'fp' => '0;35', #Purple
                      'fc' => '0;36', #Cyan
                      'fw' => '0;37', #White

                      # high foregrounds 
                      'fK' => '1;30', #blacK
                      'fR' => '1;31', #Red
                      'fG' => '1;32', #Green
                      'fY' => '1;33', #Yellow
                      'fB' => '1;34', #Blue
                      'fP' => '1;35', #Purple
                      'fC' => '1;36', #Cyan
                      'fW' => '1;37', #White

                      # backgrounds 
                      'bk' => '40', 	#blacK
                      'br' => '41', 	#Red
                      'bg' => '42', 	#Green
                      'by' => '43', 	#Yellow
                      'bb' => '44', 	#Blue
                      'bp' => '45', 	#Purple
                      'bc' => '46', 	#Cyan
                      'bw' => '47', 	#White

                      # hight backgrounds 
                      'bK' => '90', 	#blacK
                      'bR' => '91', 	#Red
                      'bG' => '92', 	#Green
                      'bY' => '93', 	#Yellow
                      'bB' => '94', 	#Blue
                      'bP' => '95', 	#Purple
                      'bC' => '96', 	#Cyan
                      'bW' => '97', 	#White
                   );

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
                
my @AC_WORDS = ( qw[ in on at next repeat noon day days year years yearly month months am pm ], keys %WEEK_DAYS_LONG, keys %MONTHS_LONG );

my %LIST_TYPES = (
                 'all'     => 'all',
                 'l'       => 'all',
                 'del'     => 'deleted',
                 'deleted' => 'deleted',
                 'd'       => 'deleted',
                 'over'    => 'overdue',
                 'overdue' => 'overdue',
                 'o'       => 'overdue',
                 'active'  => 'active',
                 'a'       => 'active',
                 );

##############################################################################

my $DATA_DIR = $ENV{ 'HOME' } . "/.resrei";
my $READLINE;
my $opt_always_yes;
my $opt_always_no;
my $opt_allow_past;
my $opt_no_colors;
my $opt_quiet;

our @args;
our @args2;
while( @ARGV )
  {
  $_ = shift;
  if( /^--+$/io )
    {
    push @args2, @ARGV;
    last;
    }
  if( /-a/ )
    {
    $DATA_DIR = shift;
    next;
    }
  if( /-y/ )
    {
    $opt_always_yes = 1;
    $opt_always_no  = 0;
    next;
    }
  if( /-n/ )
    {
    $opt_always_yes = 0;
    $opt_always_no  = 1;
    next;
    }
  if( /-p/ )
    {
    $opt_allow_past = 1;
    next;
    }
  if( /-b/ )
    {
    $opt_no_colors = 1;
    next;
    }
  if( /-q/ )
    {
    $opt_quiet = 1;
    next;
    }
  if( /^-d/ )
    {
    $DEBUG++;
    next;
    }
  if( /^(--?h(elp)?|help)$/io )
    {
    print $HELP;
    exit;
    }
  push @args, $_;
  }

dir_path_ensure( $DATA_DIR ) or die "fatal: cannot access data dir [$DATA_DIR]\n";

##############################################################################

if( @args )
  {
  exec_cmd( shift( @args ), \@args, \@args2 );
  }
else
  {
  go_interactive();
  }  


sub go_interactive
{
  my $nows = scalar localtime time;
  pc( "welcome to ^R^RES^C^REI^^ current time is ^Y^$nows\n" );
  
  while(4)
    {
    my $line = getline( "^R^res^C^rei^^: " );
    my @line = split /\s+/, $line;
    my $cmd = shift @line;
    next unless $cmd;
    
    last if $cmd =~ /^(q|x|quit|exit|zz)/i;

    exec_cmd( $cmd, \@line );
    }
}

### COMMANDS #################################################################

sub exec_cmd
{
  my $cmd   = shift;
  my $args  = shift;
  my $args2 = shift;

  return cmd_new( $args, $args2 )    if $cmd =~ /^n(ew)?/i;
  return cmd_del( $args )            if $cmd =~ /^del(ete)?/i;
  return cmd_list( $args, $args2 )   if $cmd =~ /^l(ist)?/i;
  return cmd_move( $args )           if $cmd =~ /^m(ove)?/i;
  return cmd_rename( $args, $args2 ) if $cmd =~ /^(re)?name/i;
  return cmd_repeat( $args )         if $cmd =~ /^rep(eat)?/i;
  return cmd_view( [ $1 ] )          if $cmd =~ /^(\d+)/i;
  return cmd_view( $args )           if $cmd =~ /^v(iew)?/i;
  return cmd_check( $args )          if $cmd =~ /^c(heck)?/i;
  return cmd_uncheck( $args )        if $cmd =~ /^u(n(c(heck)?)?)?/i;
  return print( $HELP )              if $cmd =~ /^h(elp)?|\?/i;
  print "error: unknown command '$cmd'! type 'help' or '?' for commands reference\n";
}

sub cmd_help
{
  my $args = shift;
  
  print $HELP;
}

sub cmd_new
{
  my $args  = shift || [];
  my $args2 = shift || [];

  my $create_args = join( ' ', @args, '--', @args2 );

  my ( $time, $repeat ) = parse_time( @$args );
  my $nows = scalar localtime( time() );
  my $tens = scalar localtime( $time  );
  my $diff = unix_time_diff_in_words_relative( time() - $time );
  
  pc( "current time: ^Y^$nows" );
  pc( "target time:  ^G^$tens^^  $diff" );
  
  if( $repeat )
    {
    my $repeat_str = repeat_time_str( $repeat );
    pc( "will repeat every ^C^$repeat_str" );
    }

  my $name;
  
  if( $args2 and @$args2 )
    {
    $name = join( ' ', @$args2 )
    }
  
  if( ! $name )
    {
    $name = getline( "new event name: " );
    }
  else
    {
    print "event name:   $name\n";
    }  


  if( ! confirm( "save this event?" ) )
    {
    print "cancelled.\n";
    return;
    }
    
  my $data = db_create_new();
  
  $data->{ 'NAME'        } = $name;  
  $data->{ 'TTIME'       } = $time;  
  $data->{ 'TTIME_STR'   } = scalar localtime $time;
  $data->{ 'TREPEAT'     } = $repeat;  
  $data->{ 'CTIME'       } = time();  
  $data->{ 'CTIME_STR'   } = scalar localtime( time() );   
  $data->{ 'CREATE_ARGS' } = $create_args;

  db_save( $data );
  my $id = $data->{ ':ID' };
    
  pc( "saved. id = ^R^ $id ^^\n" );
}

sub cmd_del
{
  my $args = shift;

  my $count = list_events( 'all', @$args  );
  
  return pc( "no events to delete" ) unless $count;
  return unless confirm( "delete listed events?" );

  for my $id ( @$args )
    {
    my $data = db_load( $id ) or next;
    next if $data->{ ':DELETED' };  
    $data->{ ':DELETED' } = time();
    db_save( $data );
    }
  
  pc( "^Wr^ DELETED! ^^ (use 'list deleted' to view deleted)" );
}

sub cmd_check
{
  my $args    =   shift;

  my $count = list_events( 'all', @$args  );

  return pc( "no events to CHECK" ) unless $count;
  return unless confirm( "CHECK listed events ^y^(repeat events will start new period)^^?" );

  for my $id ( @$args )
    {
    my $data = db_load( $id ) or next;

    my $repeat = $data->{ 'TREPEAT' };
    if( $repeat )
      {
      my $ss = $repeat->{ 'SECONDS' } || 0;
      my $mo = $repeat->{ 'MONTHS'  } || 0;
      my $yr = $repeat->{ 'YEARS'   } || 0;

      my $tt = $data->{ 'TTIME' };
      
      while(4)
        {
        $tt = utime_add_ymdhms( $tt, $yr, $mo, 0, 0, 0, $ss );
        last if $tt > time(); # repeat until next target time is in the future
        }

      $data->{ 'TTIME'     } = $tt;
      $data->{ 'TTIME_STR' } = scalar localtime $tt;
      
      }
    else
      {
      $data->{ 'CHECKED' } = time();
      }  
    $data->{ 'CHECKED_TIMES' } ||= [];
    push @{ $data->{ 'CHECKED_TIMES' } }, time();

    db_save( $data );
    list_events( 'all', $id );
    }
}

sub cmd_uncheck
{
  my $args    =   shift;

  my $count = list_events( 'all', @$args  );

  return pc( "no events to UNCHECK" ) unless $count;
  return unless confirm( "UNCHECK listed events ^y^(repeat events will start new period)^^?" );

  for my $id ( @$args )
    {
    my $data = db_load( $id ) or next;

    delete $data->{ 'CHECKED' };
    $data->{ 'UNCHECKED_TIMES' } ||= [];
    push @{ $data->{ 'UNCHECKED_TIMES' } }, time();
    db_save( $data );
    list_events( 'all', $id );
    }
}

sub cmd_list
{
  my $args = shift;
  
  my $type = $LIST_TYPES{ shift @$args } || 'all';

  return pc( "unknown list type [$type] expected one of: all, deleted, overdue" ) unless $type;

  my $list = db_list();

  my $count = list_events( $type, sort { $a <=> $b } @$list );
  
  return pc( "no events of type '$type' to list" ) unless $count or $opt_quiet;
}

sub list_events
{
  my $type = shift;
  my @ev = @_;

  @ev = sort { db_ttime( $a ) <=> db_ttime( $b ) } @ev if $type eq 'active' or $type eq 'overdue';
  
  my $count;
  for my $id ( @ev )
    {
    my $data = db_load( $id );
    if( ! $data )
      {
      pc( "^R^ $id ^^ ^Wr^event does not exists or cannot be loaded");
      next;
      }
    
    my $ttime = $data->{ 'TTIME' };
    
    if( $type eq 'overdue' )
      {
      next if $data->{ ':DELETED' } or $data->{ 'CHECKED' };
      next if $ttime > time(); 
      }
    elsif( $type eq 'deleted' )
      {
      next unless $data->{ ':DELETED' };  
      }
    elsif( $type eq 'active' )
      {
      next if $data->{ ':DELETED' } or $data->{ 'CHECKED' };
      next if $ttime - time() > 7*24*60*60;
      }
    else
      {
      # all
      next if $data->{ ':DELETED' };  
      }  
    
    my $tdiff = ( $ttime < time() ? "^Wr^ DUE " : "^G^  IN " ) . short_time_diff( time() - $ttime ) . " ^^";
    my $ttimes = strftime( "%a %b %d %H:%M %Y", localtime( $ttime ) );
    my $name  = $data->{ 'NAME' };
    my $repeat = $data->{ 'TREPEAT' } ? "^C^R^^" : ' ';
    my $del    = $data->{ ':DELETED' } ? "^R^D^^" : ' ';
    my $ggc = $count % 2 ? 'y' : 'w';
    my $ids = sprintf( "%3d", $id );
    $tdiff = "^Wg^   CHECKED   ^^" if $data->{ 'CHECKED' };
    pc( "^R^$ids ^$ggc^$ttimes^^$repeat$del$tdiff ^R^$ids ^$ggc^$name");
    $count++;
    }
  
  return $count;  
}

sub cmd_move
{
  my $args = shift;

  my $id = shift @$args;
  cmd_view( $id );

  my $data = db_load( $id );

  my ( $time, $repeat ) = parse_time( @$args );
  my $nows = scalar localtime( $data->{ 'TTIME'       } );
  my $tens = scalar localtime( $time  );
  my $diff = unix_time_diff_in_words_relative( time() - $time );
  
  pc( "current event time: ^Y^$nows" );
  pc( "move to new   time: ^G^$tens^^  $diff" );

  return unless confirm( "confirm new target time?" );
  
  $data->{ 'TTIME' } = $time;
  db_save( $data );
}

sub cmd_rename
{
  my $args = shift;

  my $id = shift @$args;
  my $name = join ' ', @$args;

  $name = getline( 'enter new name:' ) unless $name;
  return pc( 'cancelled.' ) unless $name;

  my $data = db_load( $id );
  my $old  = $data->{ 'NAME' } || '<unnamed>';

  pc( "rename ^R^ $id ^^ ^c^from^^ $old");
  pc( "             ^C^to^^ $name");

  return unless confirm( "confirm?" );

  $data->{ 'NAME' } = $name;
  db_save( $data );
  pc( "saved." );
}

sub cmd_repeat
{
  my $args = shift;

  my $id = shift @$args;
  cmd_view( $id );

  my $repeat = parse_time_repeat( $args );
  if( $repeat )
    {
    my $repeat_str = repeat_time_str( $repeat );
    pc( "will repeat every ^C^$repeat_str" );
    }
  
  return unless confirm( "confirm new repeat time?" );
  
  my $data = db_load( $id );
  $data->{ 'TREPEAT' } = $repeat;  
  db_save( $data );
}

sub cmd_view
{
  my $args = shift;
  
  $args = [ $args ] unless ref( $args ) eq 'ARRAY';

  for my $id ( @$args )
    {
    my $data = db_load( $id );
    
    if( ! $data )
      {
      pc( " ^Wr^error: cannot load event id $id " );
      }
    
    print Dumper( $data );
    print "-----------------------------------------\n";
    }
  
}

##############################################################################

sub getline
{
  my $prompt = shift;

  if( ! $READLINE )
    {
    $READLINE = Term::ReadLine::Tiny->new( "" );
    $READLINE->autocomplete( \&autocomplete );
    }

  my $input = $READLINE->readline( ec( $prompt ) );
  $input =~ s/^//g; # remove colors :))
  return $input;
}

sub confirm
{
  my $prompt = shift;

  return 0 if $opt_always_no;
  return 1 if $opt_always_yes;

  print "\n";
  my $commit = getline( "$prompt Yes/No? " );
  print "\n";
  return $commit =~ /^Y(ES)?$/i ? 1 : 0;
}

# print color, escapes are: 
# # fg bg? #
# ## -- reset
sub pc
{
  my $msg = shift;
  
  print ec( $msg ), "\n";
}

sub ec
{
  my $msg = shift;
  
  $msg =~ s/\^(([krgybpcw])([krgybpcw])?)?\^/__pc($2,$3)/gie;
  return $msg . "\e[0m";
}

sub __pc
{
  my $fg = shift;
  my $bg = shift;

  return undef if $opt_no_colors;

  $fg = $__PC_COLORS{ "f$fg" };
  $bg = $__PC_COLORS{ "b$bg" };
  
  $fg = '0'       if ! $fg;
  $bg = ';' . $bg if   $bg;
  
  return "\e[${fg}${bg}m";
} 

### DB #######################################################################

sub __make_id_fn
{
  my $id = shift;
  return "$DATA_DIR/$id.rrdata";
}

sub db_create_new
{
  my %data;

  my $id;
  my $fn;
  
  while(4)
    {
    $id = $id + 1;
    $fn = __make_id_fn( $id );
    next if -e $fn;
    last if sysopen my $F, $fn, O_CREAT | O_EXCL, 0600;
    $fn = undef;
    }  

  die "cannot create new data file in [$DATA_DIR]\n" unless $fn;

  $data{ ':ID' } = $id;
  
  return \%data;
}

sub db_list
{
  my $order = shift; # [A]lpha, [N]um, [M]time, [R]eversed
  my @list;
  
  @list = sort map { file_name( $_ ) } glob "$DATA_DIR/*.rrdata";
  
  return \@list;
}

sub db_load
{
  my $id = shift;

  my $fn = __make_id_fn( $id );
  return unstack_data( file_load( $fn ) ) or die " cannot load data from [$fn]\n";
}

sub db_save
{
  my $data = shift;

  my $id = $data->{ ':ID' };
  my $fn = __make_id_fn( $id );
  return file_save( $fn, stack_data( $data ) ) or die " cannot load data from [$fn]\n";
}

sub db_get_history
{
  my $id   = shift;
  die "to be implemented";
}

sub db_ttime
{
  my $id   = shift;
  
  my $data = db_load( $id );
  return 0 unless $data;

  return $data->{ 'TTIME' };
}

### PARSE TIME ###############################################################

sub autocomplete
{
  my $rl   = shift;
  my $text = shift;
  
  return $text unless $text =~ /\d*(\S+?)$/;
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
      next if $ta->[0] eq 'next';
      $ts = parse_time_on( $ta, $now );
      my $tss = $ts > 0 ? scalar localtime $ts : 'n/a';
      die "cannot set time in the past [$tss]\n" if $ts > 0 and $ts < $now;
      die "invalid date/time, expected timespec in the future, use -p to override\n" if ! $opt_allow_past and $ts < $now;
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
      $ts += 24*60*60 if $ts < time();
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

#print STDERR "repeat: [$_]\n";
    
    if( /^(\d+|a)$/ )
      {
      $a = $1 eq 'a' ? 1 : $1;
      $_ = lc shift @$ta;
      }

    if( /^(every|and)/ )
      {
      next;
      }
    if( /^(daily|monthly|yearly|weekly)/ )
      {
      my $type = uc substr( $1, 0, 1 );

      my $tt;
      $tt +=     1 * 24 * 60 * 60 if $type eq 'D'; # dayly
      $tt +=     7 * 24 * 60 * 60 if $type eq 'W'; # weekly
      $tr->{ 'SECONDS' } += $tt;

      $tr->{ 'MONTHS'  } += 1 if $type eq 'M'; # months
      $tr->{ 'YEARS'   } += 1 if $type eq 'Y';  # years
      next;
      }
    elsif( /^(\d*)(s(ec(onds?)?)|mi(n(utes?)?)|h(ours?|rs?)?|d(ays?)?|w(eeks?|wks?)?|mo(n|nths?)?|y(ears?|rs?)?)$/ ) # hours hour hrs hr h 
      {
      my $type = uc substr( $2, 0, 1 );
      $type = uc substr( $2, 1, 1 ) if $type eq 'M';
      my $add = $1 || $a;

      $add = 1 unless $add > 0;

      my $tt;
      $tt +=                    $add if $type eq 'S'; # seconds
      $tt +=               $add * 60 if $type eq 'I'; # minutes
      $tt +=          $add * 60 * 60 if $type eq 'H'; # hours
      $tt +=     $add * 24 * 60 * 60 if $type eq 'D'; # days
      $tt += $add * 7 * 24 * 60 * 60 if $type eq 'W'; # weeks
      
      $tr->{ 'SECONDS' } += $tt;

      $tr->{ 'MONTHS'  } += $add if $type eq 'O'; # months
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
    elsif( /^(\d+)(st|nd|rd|th)?$/ )
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
      ( $year, $mon, $day ) = ( $1, $2, $3 );
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

  die "invalid timespec during *ON* year [$year] month [$mon] day [$day]\n";
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
    
    if( /^(and)/ )
      {
      next;
      }
      
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
      unshift @$ta, $_;
      return $tt;
      #die "invalid timespec during *NEXT* [$_]\n";
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
    if( $_ =~ /(\d+)(:(\d+)?(:(\d+))?)?(am|pm)?/i )
      {
      my $h = $1;
      my $m = $3;
      my $s = $5;
      my $p = uc $6;

      $p = uc shift @$ta if ! $p and $ta->[0] =~ /^am|pm$/i;
      
      $h += 12 if $p eq 'PM' and $h >= 0 and $h <= 12;
      
      $tt = $h * 60 * 60 + $m * 60 + $s;
      }
    elsif( lc $_ eq 'noon' )
      {
      $tt = 12 * 60 * 60;
      }
    else
      {
      unshift @$ta, $_;
      return $tt;
      # die "invalid timespec during *AT* [$_]\n";
      }  
    }
  
  return $tt;
}

##############################################################################

sub repeat_time_str
{
  my $repeat = shift;

  my $ss = $repeat->{ 'SECONDS' };
  my $mo = $repeat->{ 'MONTHS'  };
  my $yr = $repeat->{ 'YEARS'   };
  my $d = int(   $ss / ( 24*60*60 ) );
  my $h = int( ( $ss % ( 24*60*60 ) ) / ( 60*60 ) );
  my $m = int( ( $ss % ( 60*60    ) ) /   60      );
  my $s = int(   $ss %   60         );
  my $repeat_str;
  
  my @repeat;
  push @repeat, "$yr years"  if $yr > 0;
  push @repeat, "$yr months" if $mo > 0;
  push @repeat, "$d days"    if $d > 0;
  push @repeat, "$h hours"   if $h > 0;
  push @repeat, "$m minutes" if $m > 0;
  push @repeat, "$s seconds" if $s > 0;

  return join ', ', @repeat;
}

sub short_time_diff
{
  my $diff = abs( shift );
  
  my $d = int( $diff / (     24*60*60 ) );
  my $o = int( $diff / (  30*24*60*60 ) );
  my $y = int( $diff / ( 365*24*60*60 ) );

  return __om( $y, "yr", "yrs" ) if $o > 14;

  return __om( $o, "mo", "mos" ) if $d > 64;
  
  return __om( $d, "day", "days" ) if $d > 0;

  my $h = int( $diff / ( 60*60 ) );

  return __om( $h, "hr", "hrs" ) if $h > 0;

  my $m = int( $diff / 60 );

  return __om( $m, "min", "mins" ) if $m > 0;

  return __om( $diff, "sec", "secs" );
}

sub __om
{
  my $n = shift;
  return sprintf "%2d %-4s", $n, ( $n == 1 ? $_[0] : $_[1] );
}

##############################################################################
