# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Picasa.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Picasa') };

BEGIN { use_ok('Picasa::Album') };
BEGIN { use_ok('Picasa::Photo') };
BEGIN { use_ok('Picasa::LoginHandler') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

