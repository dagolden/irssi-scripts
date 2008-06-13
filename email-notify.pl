# todo: grap topic changes
use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Email::Simple;
use Email::Simple::Creator;
use Email::Send;

$VERSION = '0.0.1';
%IRSSI = (
  authors     => 'David Golden',
  contact     => 'dagolden@cpan.org',
  name        => 'email-notify.pl',
  description => 'Send an email when someone is talking to you in some channel.',
  url         => 'http://echo.dagolden.com/git/?p=irssi-email-notify',
  license     => 'Apache License 2.0',
  changed     => 'Fri Jun 13 17:04:49 EDT 2008'
);

# XXX eventually, fix this so it isn't global
my %CONFIG = (
  email_from  => 'irssi <xdg@echo.dagolden.com>',
  email_to    => '9172923043@txt.att.net',
);

my $MAILER = Email::Send->new( );

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
# Private message parsing
#--------------------------------------------------------------------

sub priv_msg {
  my ($server,$msg,$nick,$address,$target) = @_;
  _send_email(from => $nick, msg => $msg);
}

#--------------------------------------------------------------------
# Printing hilight's
#--------------------------------------------------------------------

sub hilight {
  my ($dest, $text, $stripped) = @_;
  if ($dest->{level} & MSGLEVEL_HILIGHT) {
    _send_email(channel => $dest->{target}, msg => $stripped);
  }
}

#--------------------------------------------------------------------
# The actual printing
#--------------------------------------------------------------------

sub _send_email {
  my (%args) = @_;
  my $msg = $args{channel}
          ? "In $args{channel}: '$args{msg}'"
          : "$args{from} said: '$args{msg}'"
          ;

  my $email = Email::Simple->create(
    header => [
      From    => $CONFIG{email_from},
      To      => $CONFIG{email_to},
      Subject => substr($msg,0,40),
    ],
    body => length($msg) > 39 ? $msg : "",
  ) or die "Couldn't create email message";
  $MAILER->send($email) or die "Email couldn't be sent";
}

#--------------------------------------------------------------------
# Irssi::signal_add_last / Irssi::command_bind
#--------------------------------------------------------------------

Irssi::signal_add_last("message private", "priv_msg");
Irssi::signal_add_last("print text", "hilight");

#- end
