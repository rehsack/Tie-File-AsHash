use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", delim => ":"), "tie");

$hash{newkey} = "newval";

ok($hash{newkey} eq "newval", "store");
