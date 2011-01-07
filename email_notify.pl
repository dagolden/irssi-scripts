use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Simple;

$VERSION = '0.0.2';
%IRSSI = (
  authors     => 'David Golden',
  contact     => 'dagolden@cpan.org',
  name        => 'email_notify',
  description => 'Send an email when someone is talking to you in some channel.',
  url         => 'http://echo.dagolden.com/git/?p=irssi-email-notify',
  license     => 'Apache License 2.0',
  changed     => 'Sun Feb  8 22:54:27 EST 2009'
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

# Configuration handling
my %CONFIG;

sub load_config {
  %CONFIG = (
    email_from  => Irssi::settings_get_str("$IRSSI{name}_from"), 
    email_to    => Irssi::settings_get_str("$IRSSI{name}_to"),
    cooldown    => Irssi::settings_get_int("$IRSSI{name}_cooldown"),
  );
  if ( ! $CONFIG{email_from} ) {
    Irssi::print("$IRSSI{name} requires an '$IRSSI{name}_from' setting");
  }
  if ( ! $CONFIG{email_to} ) {
    Irssi::print("$IRSSI{name} requires an '$IRSSI{name}_to' setting");
  }
  if ( $CONFIG{cooldown} < 0 ) {
    $CONFIG{cooldown} = 120;
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_cooldown' defaulting to 120");
  }
}

#--------------------------------------------------------------------
# Private message parsing
#--------------------------------------------------------------------

my %last_priv_from;
sub priv_msg {
  my ($server,$msg,$nick,$address,$target) = @_;
  if ( time - ($last_priv_from{$nick} || 0 ) > $CONFIG{cooldown} ) {
    $last_priv_from{$nick} = time;
    _send_email(subject => $nick, msg => $msg);
  }
}

#--------------------------------------------------------------------
# Printing hilight's
#--------------------------------------------------------------------

my %last_hilight_from;
sub hilight {
  my ($dest, $text, $stripped) = @_;
  my ($channel, $level) = ($dest->{target}, $dest->{level});
  if ($level & MSGLEVEL_HILIGHT) {
    if ( time - ($last_hilight_from{$channel} || 0 ) > $CONFIG{cooldown} ) {
      $last_hilight_from{$channel} = time;
      _send_email(subject => $channel, msg => $stripped);
    }
  }
}

#--------------------------------------------------------------------
# The actual printing
#--------------------------------------------------------------------

sub _send_email {
  my (%args) = @_;
  my $subject = $args{subject};
  my $msg = $args{msg};

  my $email = Email::Simple->create(
    header => [
      From    => $CONFIG{email_from},
      To      => $CONFIG{email_to},
      Subject => $subject,
    ],
    body => $msg,
  ) or Irssi::print( "$IRSSI{name}: Couldn't create email '$subject'");
  Email::Sender::Simple->try_to_send($email) 
    or Irssi::print( "$IRSSI{name}: Email '$subject' couldn't be sent" );
}

#--------------------------------------------------------------------
# Irssi::signal_add_last / Irssi::command_bind
#--------------------------------------------------------------------

Irssi::settings_add_str($IRSSI{name}, "$IRSSI{name}_from", '');
Irssi::settings_add_str($IRSSI{name}, "$IRSSI{name}_to", '');
Irssi::settings_add_int($IRSSI{name}, "$IRSSI{name}_cooldown", -1);
load_config();
Irssi::signal_add_last("message private", "priv_msg");
Irssi::signal_add_last("print text", "hilight");
Irssi::signal_add_last("setup changed", "load_config")

#- end
