use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", delim => ":"), "tie");

# 6 lines in the file
ok(scalar %hash == 6, "scalar");
