use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

my @keys = qw/first foo one two bar last/;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", split => ":"), "tie");

my @keys_from_testfile = keys %hash;

# yes, keys are in order, but that may change
ok("@keys" eq "@keys_from_testfile");
