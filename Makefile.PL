use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tie::File::AsHash',
    VERSION_FROM      => 'lib/Tie/File/AsHash.pm', # finds $VERSION
    PREREQ_PM         => { "Tie::File" => undef }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/File/AsHash.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Angell <chris@chrisangell.com>') : ()),
);
