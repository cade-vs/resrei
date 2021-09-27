# NAME

RESREI is consle (text-mode) reminder utility

# SYNOPSIS

    alias rr=resrei.pl
    rr new on 11th next month at 14:30 repeat every 5 days 10 hours

    rr new on next sat at 11:30 repeat weekly
    rr new in a week and 1 day at 11pm -- evening test
    
    rr list active
    rr list all

# DESCRIPTION

RESREI aims to makes adding, checking reminders as easy as possible for users,
who actively using desktop OS machines. I know virtually everyone has a 
smartphone already but let's face it, smartphone reminder management is
&#%^@%& (censored, but read: bad) :)

Still matter of point of view, but I use a linux desktop or notebook every day
and if there is simple console utility to manage my reminders would be perfect.
So, if you are like me, you may find RESREI useful :)

RESRES has console interface or interactive mode, which doubles as internal 
command line but allows shorter commands due to having a context (i.e. active
reminder, last reminder, etc.)

RESREI is supposed to be aliased as 'rr' but you may prefer something else.
In the following text, all examples will use 'rr' instead of 'resrei.pl'.

# COMMANDS (FUNCTIONS)

RESREI has the following comands (aka functions):

## HELP

HELP displays help text:

    rr help
    rr h
    rr -h
    
All of the above will display help text with examples.

## NEW

NEW creates new reminder. It requires at least reminder titile (description):

    rr new -- title description etc.

Everything after '--' will be considered as part of reminder title. You can
omit titile in the command, so RESREI will ask you for one interactively:

    rr new
    
This may looks useless but it creates reminder with the current time, so it 
will expire immediately and will be displayed as OVERDUE. This could be useful
if you want to add a reminder for something you need to do as soon as possible.

Usually NEW will require reminder target time. RESREI has simple parser to 
allow exact time or logical time translated to exact one (i.e. next monday, 
in 5 days).

Here are few examples:

    rr new in 4 days
    rr new on 2022 march 11
    rr new next fri
    rr new in a week
    
RESREI will assume current day time for those examples. If you want to specify 
exact day time you need to use 'at':    

    rr new in 4 days at 11:30
    rr new on 2022 march 11 at noon
    rr new next fri at 4pm
    rr new in a week at midnight

Noon is always 12:00. Midnight is assumed at the end of the day at 23:59:59.
It is intentionally set at 23:59:59 and not 00:00:00 because I'd like to keep
the same date, which should be more clear I believe. So if today is 
18:00 (6pm) then tommorrow at midnight will be in 30 hours. Today in midnight
will be in 6 hours etc.

After specifying time, you can give repeat time:

    rr new tomorrow at 15:00 repeat every 5 days
    rr new tomorrow at 15:00 repeat weekly
    rr new tomorrow at 15:00 repeat every month
    rr new tomorrow at 15:00 repeat every month and a day
    
You can just give repeat time so reminder will start in repeat time starting 
today. You can optionally give day time at which reminder will trigger:

    rr new repeat 28 days at 11:00
    
"Every" can be skipped. "A" is considered "1" as expected.

RESREI time parser is not very strict and is not implemented with full grammar
parser. So it will try to match what you mean and will show what it 
understands before anything is saved.

NOTE: if you say "at 11:30 midnight" then 11:30 will be ignored and "midnight"
will be assumed. "at midngiht 11:30" will be recognised as 11:30 and 
"midnight" will be discarded.

NEW will show reminder/event ID when saved. This ID also is shown by the LIST
command described below. This ID is used for managing reminder event like
checking it or moving time or set new repeat time etc.

## LIST

LIST will show list with the reminders. LIST accepts one argument which is one
of:

    * ALL     -- show all reminders regardless time (without deleted ones)
    * OVERDUE -- show all overdue reminders
    * ACTIVE  -- show all remined not reached target time but are in the
                 warning period ahead of target time (7 days)
    * DELETED -- show deleted reminders             

RESREI will show all reminders in this format:

    ID TARGET_TIME REPEAT_FLAG DELETED_FLAG REMAININGOR_OVERDUE_TIME ID TITLE
    
Example:

    8 Sun Sep 11 11:30 2022R   IN 11 mos     8 Renew insurance
    
This is reminder '8', it is repeat reminder with target time 11th Sep 2022.
To see repeat time use the VIEW command described below.

## VIEW

To see details about single or multiple reminders:

    rr 8
    rr view 8
    
Both will show all details about remidnder event with ID 8. 
Even though VIEW command can be skipped and only ID can be specified,
VIEW has the advantage to show multiple IDs at once:

    rr view 8 16 11
    
## CHECK

CHECK marks reminder as done. For non repeating reminders, this means that
the reminder will no longer be active (unless moved to future time with the
MOVE command described below).

For repeating reminder events, CHECK will mark event as seen and move target
time ahead in the future with the repeat time. CHECK will move target time
for repeating events relative to the original target time. If multiple 
target times are missed before CHECK, RESREI will move ahead target time
to the first one which is in the future.

CHECK sets reminder to inactive status. This means that reminder is not 
deleted but marked as seen.

## UNCHECK

UNCHECK removes the check mark, which effectively sets reminder back to 
active status. For repeating reminders, UNCHECK has no meaning and will
not move back target time.

## RENAME

RENAME sets new title:

    rr rename 8 this is new title message

## MOVE

MOVE moves target time for specified reminder ID to new one:

    rr move 8 on 2022 march 2nd at 6pm
    
## REPEAT

REPEAT sets new repeat time for specified reminder ID:

    rr repeat 8 weekly
    rr repeat 8 every year and 8 days
    rr repeat 8 5 days 10 hrs

# INTERACTIVE MODE

If run without any arguments, RESREI will enter interactive mode. In this mode
all described commands will act the same but there will be command line with
editing capabilities and completion with TAB key.

# USING RESREI

Your usage cases may vary, but I use RESREI to show me all active reminders
every time when I start new terminal window. I have in my ~/.profile file:

    rr -q l a
    
On my home machine I also have RESREI show active reminders on my lock screen,
using i3lock and custom perl script for painting background lock image. If you
are interested in this case, I'll send you details on e-mail since the scope
of this document is different.

# INSTALL

Check "install-perl-cpan-modules.sh" file to see required perl modules.
You can safely run this file as script:

    chmod +x install-perl-cpan-modules.sh
    ./install-perl-cpan-modules.sh
    
As root user or as regular user if CPAN is setup accordingly.

# GITHUB REPOSITORY

    https://github.com/cade-vs/resrei

    git clone git://github.com/cade-vs/resrei.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"

    <cade@bis.bg> <cade@cpan.org> <shabanski@gmail.com>

    http://cade.noxrun.com

    https://github.com/cade-vs

## EOF
