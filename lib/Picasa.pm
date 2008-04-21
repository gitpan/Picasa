package Picasa;

use Picasa::Album;
use Picasa::Photo;
use LWP::UserAgent;

use strict;
use warnings;

our $authorization;
our $VERSION='0.02';

sub new {
  my $self = new LWP::UserAgent;
  bless $self;
  return $self;
}

sub add_album {
  my ($self,$options) = @_;
  die "user id is missing\n" unless(defined $options->{'userid'});
  Picasa::Album->add_album($options);
}

sub get_list_of_albums {
  my ($self,$options) = @_;
  die "user id is missing\n" unless(defined $options->{'userid'});
  return Picasa::Album->get_list_of_albums($options);
}

sub get_list_of_photos {
  my ($self,$options) = @_;
  die "user id is missing\n" unless(defined $options->{'userid'});
  Picasa::Photo->get_list_of_photos($options);
}

sub add_photo {
  my ($self,$options) = @_;
  die "user id is missing\n" unless(defined $options->{'userid'});
  Picasa::Photo->add_photo($options);
}

1;

=head1 NAME 

Picasa - Perl interface to Picasaweb API

=head1 SYNOPSIS

    use Picasa;

    my $api = new Picasa;
    my $albums = $api->get_list_of_albums({'userid'=><google userid>; 'access'=>'public|private'});
    $api->add_album({'userid'=><google userid>; 'album'=><album-name>; 'access'=>'public|private'});
    $api->get_list_of_photos({'userid'=><google userid>; 'album'=><album-name>; 'dir'=><path-to-download>;'access'=>'public|private'; 'size'=>'small|medium|large'});
    $api->add_photo({'userid'=><google userid>; 'album'=><album-name>; 'photo'=><photo-to-upload>; 'access'=>'public|private'; 'keywords'=><keywords>});

=head1 DESCRIPTION

    A simple interface for using Picasaweb API. This is a base class for L<Picasa::Album> and L<Picasa::Photo>, which contains the actual function definition.

=head2 METHODS

=over 4

=item C<get_list_of_albums(...)>

    To return list of albums for a given google user id. The function takes a reference to hash as an parameter, that includes the following key-value pairs.

'userid' => <google user id>(mandatory) -- google userid of the person for whom you want the album list. 

'access' => 'private|public'(optional) -- by default, returns the list of albums which have public access. You need to have 'private' value for this key if you want to list out unlisted (private) albums and accessing 'private' album requires authentication.
    
    this method returns a reference to hash whose key is album name and value is number of photos present in that album.

=item C<add_album(...)>

    To add an album in your picasaweb. The function takes a reference to hash as an parameter, that includes the following key-value pairs.

'userid' => <google user id>(mandatory) -- google userid of the person for whom you want the album list.

'album-name' => <album-name>(mandatory) -- name of album to add

'access' => 'private|public'(optional) -- by default, it marks the album to have public access. You need to have 'private' value for this key if you want to add album to have unlisted (private) access.

'keywords' => <keywords>(optional) --  tags associated with this album.

=item C<get_list_of_photos(...)>

    To download either your or others photos from picasaweb. The function takes a reference to hash as an parameter, that includes the following key-value pairs.

'userid' => <google user id>(mandatory) -- google userid of the person from whom you want the photos list.

'album-name' => <album-name>(mandatory) -- name of album to download

'access' => 'private|public'(optional) -- by default, it will search only for albums which have public access. You need to have 'private' value for this key if you want to download album which has unlisted (private) access and doing that requires authentication.

'dir' => <path-to-download>(optional) -- location to download the photos. if not specified, it will create a new directory in the format <userid>_<current-time> and photos get downloaded there.

'size' => 'small|medium|large' (optional) -- size of the photo. default is large.

=item C<add_photo(...)>

    To add a photo to an album in picasaweb. The function takes a reference to hash as an parameter, that includes the following key-value pairs.

'userid' => <google user id>(mandatory) -- google userid.

'photo' => <path-of-photo>(mandatory) -- location of photo.
    
'album-name' => <album-name>(optional) -- name of album to add the image. by default, it will add the photo in default album.
    
'keywords' => <keywords>(optional) --  tags associated with this photo.

'summary' => <summary>(optional) -- caption associated with this photo.

=back

For authentication, it uses L<Picasa::LoginHandler> module.

more functions will be added in future releases.

=head1 AUTHOR

Copyright (C) 2008, Alagarsamy, E<lt>samy@cpan.org<gt>

=head1 SEE ALSO

L<Picasa::Album>,
L<Picasa::Photo>,
L<Picasa::LoginHandler>

=cut

