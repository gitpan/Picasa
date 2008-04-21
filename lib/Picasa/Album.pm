package Picasa::Album;

use Picasa::LoginHandler;
use XML::Parser;

use strict;
use warnings;

our @ISA = qw(LWP::UserAgent Exporter);
our @EXPORT_OK=qw(add_album get_list_of_albums);
our $VERSION = '0.01';
our %list_of_albums;
our $temp_album;
our @response_ctx;

sub get_list_of_albums {
  my ($self,$options) = @_;
  my $album_feed_url = "http://picasaweb.google.com/data/feed/api/user/".$options->{'userid'}."?kind=album";
  my $response;
  if (defined $options->{'access'} and $options->{'access'} eq 'private') {
    unless(defined $Picasa::authorization) {
      my ($status, $content) = Picasa::LoginHandler->loginhandler($options);

      unless ($status =~ /200 OK/) {
         die "Login failed : $status\n";
      }
      $content =~ /^Auth=(.*)/sm;
      $Picasa::authorization = "GoogleLogin auth=$1";
      $response = $self->new->get($album_feed_url,'Authorization'=>"$Picasa::authorization");
    }  
  }
  else {
    $response = $self->new->get($album_feed_url);
  }

  if ($response->content =~ /Invalid Email address/) {
    die "Invalid email address ".$options->{'userid'}."\n";
  }
  if ($response->status_line =~ /200 OK/) {
    _parse_album_response($response->content);
    return (\%list_of_albums);
  }
  else {
    die "Not able to retrieve album list for ".$options->{'userid'}.": ".$response->status_line."\n";
  }
}

sub _parse_album_response{
  my $response_content = shift;
  my $response_parser =
        new XML::Parser(Handlers => {Start => \&album_handle_start,
                     End   => \&album_handle_end,
                     Char  => \&album_handle_char});
  $response_parser->parse($response_content);
}

sub album_handle_start {
  my($p,$element,%attrs) = @_;
  push(@response_ctx, $element);
}

sub album_handle_end {
  my($p,$element) = @_;
  pop(@response_ctx);
}

sub album_handle_char {
  my ($p,$string) = @_;
  if (@response_ctx == 3 && $response_ctx[1] eq 'entry' && $response_ctx[2] eq 'gphoto:name') {
    $temp_album = $string;
  }
  if (@response_ctx == 3 && $response_ctx[1] eq 'entry' && $response_ctx[2] eq 'gphoto:numphotos') {
    $list_of_albums{$temp_album} = $string;
  }
}

sub add_album {
  my ($self,$options) = @_;
  unless (defined $options->{'album'}) {
    die "Specify an album name to add\n";
  }
  if (defined $options->{'access'}) {
    unless (($options->{'access'} ne 'public') or ($options->{'access'} ne 'private')) {
      die "ghoto:access should have vaule of either \'private\' or \'public\'\n";
    }
  }
  my $request_add_album;
  $request_add_album  = "<entry xmlns=\'http://www.w3.org/2005/Atom\'\n";
  $request_add_album .= "    xmlns:media=\'http://search.yahoo.com/mrss/\'\n";
  $request_add_album .= "    xmlns:gphoto=\'http://schemas.google.com/photos/2007\'>\n";
  $request_add_album .= "  <title type=\'text\'>$options->{'album'}</title>\n";
  $request_add_album .= "  <summary type=\'text\'>$options->{'summary'}</summary>\n" if(defined $options->{'summary'});
  $request_add_album .= "  <gphoto:location>$options->{'location'}</gphoto:location>\n" if (defined $options->{'location'});
  $request_add_album .= "  <gphoto:access>$options->{'access'}</gphoto:access>\n" if (defined $options->{'access'});
  $request_add_album .= "  <gphoto:commentingEnabled>$options->{'commentingEnabled'}</gphoto:commentingEnabled>\n" if (defined $options->{'commentingEnabled'});
  $request_add_album .= "  <gphoto:timestamp>$options->{'timestamp'}</gphoto:timestamp>\n" if (defined $options->{'timestamp'});
  if (defined $options->{'keywords'}) {
    $request_add_album .= "  <media:group>\n";
    $request_add_album .= "     <media:keywords>$options->{'keywords'}</media:keywords>\n";
    $request_add_album .= "  </media:group>\n";
  }
  $request_add_album .= "    <category scheme=\'http://schemas.google.com/g/2005#kind\'\n";
  $request_add_album .= "       term=\'http://schemas.google.com/photos/2007#album\'></category>\n";
  $request_add_album .= "</entry>\n";

  unless(defined $Picasa::authorization) {
    my ($status, $content) = Picasa::LoginHandler->loginhandler($options);

    unless ($status =~ /200 OK/) {
       die "Login failed : $status\n";
    }
    $content =~ /^Auth=(.*)/sm;
    $Picasa::authorization = "GoogleLogin auth=$1";
  }
   
  my $add_album_request = HTTP::Request->new(POST=>"http://picasaweb.google.com/data/feed/api/user/$options->{'userid'}",['Authorization'=>"$Picasa::authorization"],);
  $add_album_request->content_type('application/atom+xml');
  $add_album_request->content($request_add_album);

  my $add_album_response = $self->new->request($add_album_request);

  if ($add_album_response->status_line =~ /201 Created/) {
    if ($add_album_response->content =~ /<gphoto:name>(.*)<\/gphoto:name>/) {
      print "Album $1 created\n";
    }
  }
  else {
    die "Album ".$options->{'album'}." not created : ".$add_album_response->status_line."\n";
  }
}

1;

=head1 NAME

Picasa::Album -- perl interface for performing all album related functions in picasaweb

=head1 DESCRIPTION

    A simple interface for performing album related operations like adding an album, getting album info. etc. 

=head2 METHODS

=over 4

=item C<get_list_of_albums(...)>

=item C<add_album(...)>

information about these functions are covered in L<Picasa> module.

more functions will be added in future releases.

=back

=head1 AUTHOR

Copyright (C) 2008, Alagarsamy, E<lt>samy@cpan.org<gt>
    
=head1 SEE ALSO

L<Picasa>,
L<Picasa::Photo>,
L<Picasa::LoginHandler>

=cut
  

