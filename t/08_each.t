use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

my @vals = qw/line bar uno dos bar line/;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", split => ":"), "tie");

my $vals;

while (my ($key, $val) = each %hash)
{

	$vals++;

}

# yes, hashes are in same order, though that may change
ok($vals == scalar %hash);
