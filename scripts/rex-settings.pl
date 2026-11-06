#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);

my $domain = 'com.superlogical.rex';
my $file   = "$RealBin/../terminal/rex/settings.plist";

open my $in, '<', $file or die "$file: $!\n";
my $plist = do { local $/; <$in> };
close $in or die "$file: $!\n";

while ($plist =~ m{^\t<key>([^<]*)</key>\n\t(<(string|integer|real)>[^<]*</\3>|<(?:true|false)/>)$}mg) {
  system('defaults', 'write', $domain, $1, $2) == 0 or die "defaults write $1 failed\n";
}
