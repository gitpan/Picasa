package Picasa::LoginHandler;

use LWP::UserAgent;
use Term::ReadPassword;

use strict;
use warnings;

our @ISA = qw(LWP::UserAgent);
our $VERSION = '0.01';

sub loginhandler {
  my ($self,$options) = @_;
  my ($userid,$passwd);
  my %login_param;
  unless (defined $options->{'userid'}) {
    print "Enter the gmail id : ";
    $options->{'userid'} = <STDIN>;
    chomp($options->{'userid'});
  }
  unless (defined $options->{'passwd'}) {
    $options->{'passwd'} = read_password('Password (for '.$options->{'userid'}.'): ');
  }
  $login_param{'accounttype'} = 'HOSTED_OR_GOOGLE';
  $login_param{'Email'} = $options->{'userid'}.'@gmail.com';
  $login_param{'Passwd'} = $options->{'passwd'};
  $login_param{'service'} = 'lh2';
  my $login_response = $self->new->post("https://www.google.com/accounts/ClientLogin",\%login_param);
  return($login_response->status_line,$login_response->content);
}

=head1 NAME

Picasa::LoginHandler -- perl interface for performing login operations in picasaweb.

=head1 DESCRIPTION

  This module will be used by L<Picasa::Album> and L<Picasa::Photo> for doing authentication when adding photo/album or when accessing private album.

=head1 AUTHOR 

Copyright (C) 2008, Alagarsamy, E<lt>samy@cpan.org<gt>

=head1 SEE ALSO

L<Picasa>,
L<Picasa::Album>,
L<Picasa::LoginHandler>

=cut
  

