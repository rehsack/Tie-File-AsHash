use Test::More tests => 2;

BEGIN { use_ok('Tie::File::AsHash') };

my $testversion = "0.04";

ok($Tie::File::AsHash::VERSION == $testversion, "Test version check -- test version must match module version");
