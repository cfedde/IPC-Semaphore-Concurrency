use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Semaphore::Concurrency',
    ABSTRACT_FROM     => 'lib/IPC/Semaphore/Concurrency.pm', # retrieve abstract from module
    AUTHOR            => 'Thomas Guyot-Sionnest <tguyot@gmail.com>',
    VERSION_FROM      => 'lib/IPC/Semaphore/Concurrency.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
	    'Carp'            => 0,
	    'POSIX'           => 0,
	    'IPC::SysV'       => 0,
	    'IPC::Semaphore'  => 0,
	    'Test::More' 	    => 0,
	    'Exporter'        => 0,
    },
    META_MERGE        => {
      'meta-spec'       => { version => 2 },
      resources         => {
        repository        => {
          type              => 'git',
          url               => 'https://github.com/dermoth/IPC-Semaphore-Concurrency.git',
          web               => 'https://github.com/dermoth/IPC-Semaphore-Concurrency',
        },
      },
    },
);
