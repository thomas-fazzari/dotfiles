#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use POSIX   qw(strftime);

my $source  = 'https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js';
my $marker  = "// Enter your personal overrides below this line:\n";
my $firefox = "$ENV{HOME}/Library/Application Support/Firefox";

my $userjs = `curl -fsSL $source`;
$? == 0 or die "Failed to download $source\n";
$userjs =~ s/\r\n/\n/g;
my ($version) = $userjs =~ /^ \* version: (\S+)/m or die "No version in Betterfox user.js\n";

open my $overrides, '<', "$RealBin/user-overrides.js" or die "user-overrides.js: $!\n";
my $mine = do { local $/; <$overrides> };
close $overrides;
$userjs =~ s/\Q$marker\E/$marker$mine/ or die "Overrides marker not found in Betterfox $version\n";

open my $out, '>', "$RealBin/user.js" or die "user.js: $!\n";
print $out $userjs;
close $out or die "user.js: $!\n";
print "build user.js from Betterfox $version\n";

open my $installs, '<', "$firefox/installs.ini" or die "$firefox/installs.ini: $!\n";
my ($profile) = map { /^Default=(.+)$/ ? $1 : () } <$installs>;
close $installs;
defined $profile or die "No default profile in installs.ini\n";
$profile = "$firefox/$profile" unless $profile =~ m{^/};

my ($link, $target) = ("$profile/user.js", "$RealBin/user.js");
if (-l $link && readlink($link) eq $target) {
  print "ok $link\n";
}
else {
  if (-l $link) {
    unlink $link or die "$link: $!\n";
  }
  elsif (-e $link) {
    my $backup = "$link.backup-" . strftime('%Y%m%d-%H%M%S', localtime);
    rename $link, $backup or die "$link: $!\n";
    print "backup $link\n";
  }
  symlink $target, $link or die "$link: $!\n";
  print "link $link -> $target\n";
}

print "Firefox is running: quit it with Cmd+Q and relaunch to apply\n" if system('pgrep -xq firefox') == 0;
