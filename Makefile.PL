use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tie::File::AsHash',
    VERSION_FROM      => 'lib/Tie/File/AsHash.pm',
    PREREQ_PM         => { "Tie::File" => undef },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/File/AsHash.pm',
       AUTHOR         => 'Chris Angell <chris@chrisangell.com>') : ()),
);
