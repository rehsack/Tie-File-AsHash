package Tie::File::AsHash;

use strict;
# use warnings;
use vars qw($VERSION);
use Carp;
use Tie::File;

$VERSION = "0.03";

sub TIEHASH {

	croak usage() if @_ % 2;

	my ($obj, $filename, %opts) = @_;

	# set delimiter and croak if none was supplied
	my $split = delete $opts{split} or croak usage();

	# set join, an optional argument
	my $join = delete $opts{join};

	# if split's value is a regex and join isn't specified, croak
	croak "Tie::File::AsHash error: no 'join' option specified and 'split' option is a regular expression\n", usage()
		if ref($split) eq "Regexp" and not defined $join;
	
	# the rest of the options can feed right into Tie::File
	# Tie::File can worry about checking the arguments for validity, etc.
	tie my @file, 'Tie::File', $filename, %opts or return; 

	return bless { split => $split, join => $join, file => \@file }, $obj;

}

sub FETCH {

	my ($self, $key) = @_;

	# find the key and get corresponding value
	for (@{$self->{file}}) {

		return $1 if /^\Q$key\E$self->{split}(.*)/s;

	}

}  

sub STORE {

	my ($self, $key, $val) = @_;

	# look for $key in the file and replace value if $key is found
	for (@{$self->{file}}) {

		# found the key? good. replace the entire line with the correct key, delim, and value
		if (/^\Q$key\E$self->{split}/s) {

			$_ = $key . (exists $self->{join} ? $self->{join} : $self->{split}) . $val;
			return;

		}

	}

	# if key doesn't exist in the file, append to end of file
	push @{$self->{file}}, $key . (defined $self->{join} ? $self->{join} : $self->{split}) . $val;

}

sub DELETE {

	my ($self, $key) = @_;

	# first, look for the key in the file
	# next, delete the line in the file
	# finally, return the value, which might not contain anything
	# perl's builtin delete() returns the deleted value, so emulate the behavior

	for my $i (0 .. $#{ $self->{file} } ) {

		if ($self->{file}->[$i] =~ /^\Q$key\E$self->{split}(.*)/s) {

			splice @{$self->{file}}, $i, 1;  # remove entry from file
			return $1;

		}

	}

}

sub CLEAR { @{ $_[0]->{file} } = () }

sub EXISTS {

	my ($self, $key) = @_;

	for (@{$self->{file}}) {

		return 1 if /^\Q$key\E$self->{split}/s;

	}

}  

sub FIRSTKEY {

	my ($self) = @_;
	
	# deal with empty files
	return unless exists $self->{file}->[0];

	my ($val) = $self->{file}->[0] =~ /^(.*?)$self->{split}/s;

	# for NEXTKEY
	$self->{index} = 1;

	return $val;

}  

sub NEXTKEY {

	my ($self) = @_;
	
	# deal with one-line files
	if ($self->{index} == 1) {

		return unless exists $self->{file}->[1];

	}

	# and the end of the file
	return if $self->{index} >= @{$self->{file}};

	my ($val) = $self->{file}->[ $self->{index} ] =~ /^(.*?)$self->{split}/s;

	return $val;

}

sub SCALAR {

	my ($self) = @_;
	
	# can't think of any other good use for scalar %hash besides this
	return scalar @{$self->{file}};

}

sub UNTIE {

	my ($self) = @_;
	
	untie @{$self->{file}};

}

sub DESTROY { UNTIE(@_) }

sub usage {

	return "usage: tie %hash, 'Tie::File::AsHash', 'filename', split => ':' [, join => '#', 'Tie::File option' => value, ... ]\n";

}


=head1 NAME

Tie::File::AsHash - Like Tie::File but access lines using a hash instead of an
array

=head1 SYNOPSIS

 use Tie::Hash::AsHash;

 tie my %hash, 'Tie::File::AsHash', 'filename', split => ':'
 	or die "Problem tying %hash: $!";

 print $hash{foo};                  # access hash value via key name
 $hash{foo} = "bar";                # assign new value
 my @keys = keys %hash;             # get the keys
 my @values = values %hash;         # ... and values
 exists $hash{perl};                # check for existence
 delete $hash{baz};                 # delete line from file
 $hash{newkey} = "perl";            # entered at end of file
 while (($key,$val) = each %hash)   # iterate through hash
 %hash = ();                        # empty file

 untie %hash;                       # all done

Here is sample text that would work with the above code when contained in a
file:

 foo:baz
 key:val
 baz:whatever

=head1 DESCRIPTION

C<Tie::File::AsHash> uses C<Tie::File> and perl code so files can be tied to
hashes.  C<Tie::File> does all the hard work while C<Tie::File::AsHash> works
a little magic of its own.

The module was initially written for managing htpasswd-format password files.

=head1 USAGE

 use Tie::File::AsHash;
 tie %hash, 'Tie::File::AsHash', 'filename', split => ':'
 	or die "Problem tying %hash: $!";

 (use %hash like a regular ol' hash)

 untie %hash;  # changes saved to disk

Easy enough eh?

New key/value pairs are appended to the end of the file, C<delete> removes lines
from the file, C<keys> and C<each> work as expected, and so on.

C<Tie::File::AsHash> will not die or exit if there is a problem tying a
file, so make sure to check the return value and check C<$!> as the examples do.

=head2 OPTIONS

The only argument C<Tie::File::AsHash> requires is the "split" option, besides
a filename.  The split option's value is the delimiter that exists in the file
between the key and value portions of the line.  It may be a regular
expression, and if so, the "join" option must be used to tell
C<Tie::File::AsHash> what to stick between the key and value when writing
to the file.  Otherwise, the module dies with an error message.

 tie %hash, 'Tie::File::AsHash', 'filename',  split => qr(\s+), join => " "
 	or die "Problem tying %hash: $!";

Obviously no one wants lines like "key(?-xism:\s+)val" in their files. 

All other options are passed directly to C<Tie::File>, so read its
documentation for more information.

=head1 CAVEATS

When C<keys>, C<values>, or C<each> is used on the hash, the values are
returned in the same order as the data exists in the file, from top to
bottom, though this behavior should not be relied on and is subject to change
at any time (but probably never will).

C<Tie::File::AsHash> doesn't force keys to be unique.  If there are multiple
keys, the first key in the file, starting at the top, is used. However, when
C<keys>, C<values>, or C<each> is used on the hash, every key/value combination
is returned, including duplicates, triplicates, etc.

Keys can't contain the split character.  Look at the perl code that
C<Tie::File::AsHash> is comprised of to see why (look at the regexes).  Using
a regex for the split value may be one way around this issue.

C<Tie::File::AsHash> hasn't been optimized much.  Maybe it doesn't need to be.
Optimization could add overhead.  Maybe there can be options to turn on and off
various types of optimization?

=head1 EXAMPLES

=head2 changepass.pl

C<changepass.pl> changes password file entries when the lines are of
"user:encryptedpass" format.  It can also add users.

 #!/usr/bin/perl -w

 use strict;
 use Tie::File::AsHash;

 die "Usage: $0 user password" unless @ARGV == 2;
 my ($user, $newpass) = @ARGV;
 
 tie my %users, 'Tie::File::AsHash', '/pwdb/users.txt', split => ':'
     or die "Problem tying %hash: $!";

 # username isn't in the password file? see if the admin wants it added
 unless (exists $users{$user}) {
	 
	 print "User '$user' not found in db.  Add as a new user? (y/n)\n";
	 chomp(my $y_or_n = <STDIN>);
	 set_pw($user, $newpass) if $y_or_n =~ /^[yY]/;

 } else {

	 set_pw($user, $newpass);
	 print "Done.\n";

 }
	 
 sub set_pw { $users{$_[0]} = crypt($_[1], "AA") }

=head2 Using the join option
 
Here's code that would allow the delimiter to be ':' or '#' but prefers '#':

 tie my %hash, 'Tie::File::AsHash', 'filename', split => qr/[:#]/, join => "#" or die $!;

Say you want to be sure no ':' delimiters existed in the file:

 while (my ($key, $val) = each %hash) {

 	$hash{$key} = $val;

 }

=head1 AUTHOR

Chris Angell <chris@chrisangell.com>

Feel free to email me with suggestions, fixes, etc.

Thanks to Mark Jason Dominus for authoring the superb Tie::File module.

=head1 COPYRIGHT

Copyright (C) 2004, Chris Angell.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, including any version of Perl 5.

=head1 SEE ALSO

perl(1), perltie(1), Tie::File(1)

=cut

# vim:ts=4

1;
