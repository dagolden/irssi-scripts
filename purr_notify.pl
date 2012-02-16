use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '0.0.1';
%IRSSI = (
  authors     => 'David Golden',
  contact     => 'dagolden@cpan.org',
  name        => 'purr_notify',
  description => 'Send a purr when someone is talking to you in some channel.',
  url         => 'http://echo.dagolden.com/git/?p=irssi-purr-notify',
  license     => 'Apache License 2.0',
  changed     => 'Sun Feb 15 22:54:27 EST 2012'
);

#--------------------------------------------------------------------
# In parts based on fnotify.pl 0.0.3 by Thorsten Leemhuis 
# http://www.leemhuis.info/files/fnotify/
# In parts based on knotify.pl 0.1.1 by Hugo Haas
# http://larve.net/people/hugo/2005/01/knotify.pl
# which is based on osd.pl 0.3.3 by Jeroen Coekaerts, Koenraad Heijlen
# http://www.irssi.org/scripts/scripts/osd.pl
#
# Other parts based on notify.pl from Luke Macken
# http://fedora.feedjack.org/user/918/
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Configuration handling
#--------------------------------------------------------------------
my %CONFIG;

sub load_config {
  %CONFIG = (
    url         => Irssi::settings_get_str("$IRSSI{name}_url"), 
    cooldown    => Irssi::settings_get_int("$IRSSI{name}_cooldown"),
  );
  if ( ! length $CONFIG{url} ) {
    $CONFIG{url} = "http://localhost:7877/";
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_port' defaulting to $CONFIG{url}");
  }
  if ( $CONFIG{cooldown} < 0 ) {
    $CONFIG{cooldown} = 120;
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_cooldown' defaulting to $CONFIG{cooldown}");
  }
}


#--------------------------------------------------------------------
# Handle private messages
#--------------------------------------------------------------------

my %last_priv_from;
sub priv_msg {
  my ($server,$msg,$nick,$address,$target) = @_;
  if ( time - ($last_priv_from{$nick} || 0 ) > $CONFIG{cooldown} ) {
    $last_priv_from{$nick} = time;
    _send_purr($nick => $msg);
  }
}

#--------------------------------------------------------------------
# Handle public hilights
#--------------------------------------------------------------------

my %last_hilight_from;
sub hilight {
  my ($dest, $text, $stripped) = @_;
  my ($channel, $level) = ($dest->{target}, $dest->{level});
  if ($level & MSGLEVEL_HILIGHT) {
    if ( time - ($last_hilight_from{$channel} || 0 ) > $CONFIG{cooldown} ) {
      $last_hilight_from{$channel} = time;
      _send_purr($channel => $stripped);
    }
  }
}

#--------------------------------------------------------------------
# Send notification message
#--------------------------------------------------------------------

sub _send_purr {
  system("/usr/bin/curl", $CONFIG{url}, "-s", "-d", join("\n",@_));
}

#--------------------------------------------------------------------
# Hook into irssi settings and signals
#--------------------------------------------------------------------

Irssi::settings_add_str($IRSSI{name}, "$IRSSI{name}_url", '');
Irssi::settings_add_int($IRSSI{name}, "$IRSSI{name}_cooldown", -1);

load_config();

Irssi::signal_add_last("message private", \&priv_msg);
Irssi::signal_add_last("print text", \&hilight);
Irssi::signal_add_last("setup changed", \&load_config);

