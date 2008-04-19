use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Picasa',
    VERSION_FROM      => 'lib/Picasa.pm', # finds $VERSION
    PREREQ_PM         => {LWP::UserAgent => 0,
                          XML::Parser => 0,
                          Term::ReadPassword => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Picasa.pm', # retrieve abstract from module
       AUTHOR         => 'Alagarsamy <samy@cpan.org>') : ()),
);
