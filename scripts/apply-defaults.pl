#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(basename);
use FindBin        qw($RealBin);

for my $file (glob "$RealBin/../macos/defaults/*.plist") {
  my $domain = basename($file, '.plist');
  open my $in, '<', $file or die "$file: $!\n";
  my $plist = do { local $/; <$in> };
  close $in or die "$file: $!\n";

  while ($plist =~ m{^\t<key>([^<]*)</key>\n\t(<\w+/>|<(\w+)>[^\n]*?</\3>|<(\w+)>\n.*?\n\t</\4>)$}msg) {
    my ($key, $value) = ($1, $2);
    system('defaults', 'write', $domain, $key, $value) == 0 or die "defaults write $domain $key failed\n";
  }
  print "applied $domain\n";
}
