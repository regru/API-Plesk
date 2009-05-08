use ExtUtils::MakeMaker;

WriteMakefile
(
          NAME         => 'API::Plesk',
          AUTHOR       => 'NRG <pavel.odintsov@googlemail.com>',
          LICENSE      => 'perl',
          ABSTRACT     => 'API::Plesk - OOP interface to the Plesk XML API',
          VERSION_FROM => 'lib/API/Plesk.pm',
          PREREQ_PM    => {
                           'Carp'             => '0',
                           'Data::Dumper'     => '0',
                           'Getopt::Long'     => '0',
                           'HTTP::Request'    => '0',
                           'LWP::UserAgent'   => '0',
                           'Test::More'       => '0',
                           'Test::LongString' => '0',
                           'URI'              => '0',
                          },
          INSTALLDIRS  => 'site',
          EXE_FILES    => [],
          PL_FILES     => {}
        )
;
