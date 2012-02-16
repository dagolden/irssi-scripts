use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Simple;

$VERSION = '0.0.1';
%IRSSI = (
  authors     => 'David Golden',
  contact     => 'dagolden@cpan.org',
  name        => 'summon_notify',
  description => 'Send an email when someone is talking to you in some channel.',
  url         => 'https://github.com/dagolden/irssi-scripts/',
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
    start_hour  => Irssi::settings_get_int("$IRSSI{name}_start_hour"),
    stop_hour  => Irssi::settings_get_int("$IRSSI{name}_stop_hour"),
  );
  if ( ! $CONFIG{email_from} ) {
    Irssi::print("$IRSSI{name} requires an '$IRSSI{name}_from' setting");
  }
  if ( ! $CONFIG{email_to} ) {
    Irssi::print("$IRSSI{name} requires an '$IRSSI{name}_to' setting");
  }
  if ( $CONFIG{start_hour} < 0 || $CONFIG{start_hour} > 23 ) {
    $CONFIG{start_hour} = 9;
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_start_hour' defaulting to 9");
  }
  if ( $CONFIG{stop_hour} < 0 || $CONFIG{stop_hour} > 23 ) {
    $CONFIG{stop_hour} = 20;
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_stop_hour' defaulting to 20");
  }
  if ( $CONFIG{cooldown} < 0 ) {
    $CONFIG{cooldown} = 600;
    Irssi::print("$IRSSI{name} setting '$IRSSI{name}_cooldown' defaulting to 600");
  }
}

#--------------------------------------------------------------------------#
# cache my nick
#--------------------------------------------------------------------------#
my $alert_nick = uc Irssi::settings_get_str("nick");
my $alert_re;
sub own_nick {
  my ($server, $new_nick, $old_nick) = @_;
  my $alert_nick = uc $new_nick;
  undef $alert_re;
}

#--------------------------------------------------------------------
# Public message parsing
#--------------------------------------------------------------------

my %last_summon_from;
sub pub_msg {
  my ($server,$msg,$nick,$address,$target) = @_;

  # check for summon message
  $alert_re ||= qr/(?:$alert_nick\s+){3}COME TO ME/;
  return unless $msg =~ $alert_re;

  # alert if since cooldown
  if ( time - ($last_summon_from{$target} || 0 ) > $CONFIG{cooldown} ) {
    $last_summon_from{$target} = time;
    my $alert_msg = "Summoned to $target";
    my $time = scalar localtime;
    my (undef,undef,$hour) = localtime;
    return if $CONFIG{start_hour} != $CONFIG{stop_hour} && 
      ( $hour < $CONFIG{start_hour} || $hour >= $CONFIG{stop_hour} );
    _send_email(subject => $alert_msg, msg => "$alert_msg at $time");
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
Irssi::settings_add_int($IRSSI{name}, "$IRSSI{name}_cooldown", 600);
Irssi::settings_add_int($IRSSI{name}, "$IRSSI{name}_start_hour", 9);
Irssi::settings_add_int($IRSSI{name}, "$IRSSI{name}_stop_hour", 20);
load_config();
Irssi::signal_add_last("message public", "pub_msg");
Irssi::signal_add_last("setup changed", "load_config");
Irssi::signal_add_last("own nick", "own_nick");

#- end
