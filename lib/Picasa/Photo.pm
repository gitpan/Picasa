package Picasa::Photo;

use Picasa::LoginHandler;
use Picasa::Album qw(get_list_of_albums);
use XML::Parser;
use File::Basename;

use strict;
use warnings;

our @ISA = qw(LWP::UserAgent);
our $VERSION = '0.01';
our @list_of_photos;
our $size;
our @response_ctx;

sub get_list_of_photos {
  my ($self,$options) = @_;
  my $response;
  $size = $options->{'size'} if(defined $options->{'size'});
  my $photos_feed_url = "http://picasaweb.google.com/data/feed/api/user/".$options->{'userid'};
  $photos_feed_url .= "/album/".$options->{'album'} if(defined $options->{'album'});
  $photos_feed_url .= '?kind=photo';
  my ($album_exists,$numphotos) = _check_exists_album($self,$options) if(defined $options->{'album'});
  if (defined $options->{'album'}) {
    die "Album ".$options->{'album'}." not there for user ".$options->{'userid'}."\n" if($album_exists == 0);
    die "There are no photos in album ".$options->{'album'}."\n" if ($numphotos == 0);
  }
  if (defined $options->{'access'} and $options->{'access'} eq 'private') {
    $response = $self->new->get($photos_feed_url,'Authorization'=>"$Picasa::authorization");
  }
  else {
    $response = $self->new->get($photos_feed_url);
  }
  _parse_photo_response($response->content);
  download_photos($self,$options);
}

sub _check_exists_album{
  my ($self,$options) = @_;
  my $list_of_albums = get_list_of_albums($self,$options);
  foreach (keys %$list_of_albums) {
    if ($_ eq $options->{'album'}) {
      return (1,$list_of_albums->{$_});
    }
  }
  return (0,0);
}

sub _parse_photo_response{
  my ($response_content) = @_;
  my $response_parser =
        new XML::Parser(Handlers => {Start => \&photos_handle_start,
                     End   => \&photos_handle_end,
                     Char  => \&photos_handle_char});
  @response_ctx = ();
  @list_of_photos = ();
  $response_parser->parse($response_content);
}

sub photos_handle_start {
  my($p,$element,%attrs) = @_;
  push(@response_ctx, $element);
  if (@response_ctx == 4 && $response_ctx[2] eq 'media:group') {
    if ((defined $size) && ($size eq "small") && ($response_ctx[3] eq 'media:thumbnail')) {
      if ($attrs{'url'} =~ /s72/) {
        push(@list_of_photos,$attrs{'url'});
      }
    }
    if ((defined $size) && ($size eq "medium") && ($response_ctx[3] eq 'media:thumbnail')) {
      if ($attrs{'url'} =~ /s288/) {
        push(@list_of_photos,$attrs{'url'});
      }
    }
    if ((defined $size) && ($size eq "large") && ($response_ctx[3] eq 'media:content')) {
      push(@list_of_photos,$attrs{'url'});
    }
    if ((not defined $size) && ($response_ctx[3] eq 'media:content')) {
      push(@list_of_photos,$attrs{'url'});
    }
  }
}

sub photos_handle_end {
  my($p,$element) = @_;
  pop(@response_ctx);
}

sub photos_handle_char {
  my ($p,$string) = @_;
}

sub download_photos {
  my ($self,$options) = @_;
  my $directory_to_download;
  if (defined $options->{'dir'}) {
    unless (-d $options->{'dir'}) {
      system("mkdir -p ".$options->{'dir'});
    }
    $directory_to_download = $options->{'dir'};
  }
  else {
    $directory_to_download = $options->{'userid'}."_".time();
    system("mkdir -p $directory_to_download");
    unless (-d $directory_to_download) {
      die 'Not able to create dir for downloading.specify one with \'dir\'=>\'location\'\n';
    }
  }  
  my $workdir = `pwd`;
  chdir ($directory_to_download);
  foreach my $photo_url (@list_of_photos) {
    my $res = LWP::UserAgent->new->get($photo_url);
    my $filename = basename($photo_url);
    $filename =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    open(FH,">",$filename);
    binmode FH;
    print FH $res->content;
    close FH;
    if ($res->status_line =~ /200 OK/) {
      print "photo $filename downloaded as $directory_to_download/$filename\n";
    }
  }
  chdir($workdir);
}

sub add_photo {
  my ($self,$options) = @_;
  my $request_url;
  if (defined $options->{'album'}) {
    my $list_of_albums = $self->get_list_of_albums($options);
    unless (grep {$_ eq $options->{'album'}} (keys %$list_of_albums)) {
      die 'Album '.$options->{'album'}.' not there\n';
    }
    else {
      $request_url = "http://picasaweb.google.com/data/feed/api/user/".$options->{'userid'}."/album/".$options->{'album'};
    }
  }
  else {
    $request_url = "http://picasaweb.google.com/data/feed/api/user/".$options->{'userid'}."/albumid/default";
  }

  if (defined $options->{'photo'}) {
    unless(-f $options->{'photo'}) {
      die "No photo ".$options->{'photo'}." found";
    }
  }
  else {
    die "No photo defined\n";
  }

  my $add_photo_xml;
  $add_photo_xml .= "<entry xmlns=\'http://www.w3.org/2005/Atom\' \n xmlns:exif=\'http://schemas.google.com/photos/exif/2007\' \n xmlns:geo=\'http://www.w3.org/2003/01/geo/wgs84_pos#\' \n xmlns:gml=\'http://www.opengis.net/gml\' \n xmlns:georss=\'http://www.georss.org/georss\' \n xmlns:media=\'http://search.yahoo.com/mrss/\' \n xmlns:gphoto=\'http://schemas.google.com/photos/2007\'> \n";
  $add_photo_xml .= "  <title>$options->{'title'}</title>\n" if (defined $options->{'title'});
  $add_photo_xml .= "  <title>".basename($options->{'photo'})."</title>\n" if (not defined $options->{'title'});
  $add_photo_xml .= "  <summary>$options->{'summary'}</summary>\n" if (defined $options->{'summary'});
  if (defined $options->{'keywords'}) {
    $add_photo_xml .= "<media:group>\n";
    $add_photo_xml .= "    <media:keywords>$options->{'keywords'}</media:keywords>\n";
    $add_photo_xml .= "</media:group>\n";
  }
  $add_photo_xml .= "  <category scheme=\"http://schemas.google.com/g/2005#kind\"\n";
  $add_photo_xml .= "      term=\"http://schemas.google.com/photos/2007#photo\"/>\n";
  $add_photo_xml .= "</entry>";
  my $add_photo_data;
  {
    local $/;
    open(FH, $options->{'photo'});
    binmode(FH);
    $add_photo_data = <FH>;
    close(FH);
  }

  unless (defined $Picasa::authorization) {
    my ($status, $content) = Picasa::LoginHandler->loginhandler($options);

    unless ($status =~ /200 OK/) {
       die "Login failed : $status\n";
    }
    $content =~ /^Auth=(.*)/sm;
    $Picasa::authorization = "GoogleLogin auth=$1";
 }
  my $add_photo_request = HTTP::Request->new(POST=>$request_url,['Authorization' => $Picasa::authorization,'Content-Type'=>'multipart/related','MIME-version'=>'1.0']);
  $add_photo_request->add_part(HTTP::Message->new(['Content-Type' => 'application/atom+xml'], $add_photo_xml));
  $add_photo_request->add_part(HTTP::Message->new(['Content-Type' => 'image/jpeg'], $add_photo_data));

  my $add_photo_response = $self->new->request($add_photo_request);
  if ($add_photo_response->status_line =~ /201 Created/) {
    $add_photo_response->content =~ /<id>(.*)<\/id>/;
    print "Photo ".$options->{'photo'}." uploaded as $1\n";
  }
  else {
    die "Photo ".$options->{'photo'}." not created : ".$add_photo_response->status_line."\n";  
  }
}

1;

=head1 NAME

Picasa::Album -- perl interface for performing all photo related functions in picasaweb

=head1 DESCRIPTION
    A simple interface for performing operations related to photo like adding an photo, downloading list of photos from album. etc.

=head2 METHODS

=over 4

=item C<get_list_of_photos(...)>

=item C<add_photo(...)>

information about these functions are covered in L<Picasa> module.

more functions will be added in future releases.

=back

=head1 AUTHOR

Copyright (C) 2008, Alagarsamy, E<lt>samy@cpan.org<gt>

=head1 SEE ALSO

L<Picasa>,
L<Picasa::Album>,
L<Picasa::LoginHandler>

=cut

