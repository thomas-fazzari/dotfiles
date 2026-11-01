#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use POSIX   qw(strftime);

my $source = 'https://raw.githubusercontent.com/yokoffing/Betterfox/main/zen/user.js';
my $marker = "// Enter your personal overrides below this line:\n";
my ($zen)  = grep {-d} "$ENV{HOME}/Library/Application Support/zen",
  ($ENV{XDG_CONFIG_HOME} // "$ENV{HOME}/.config") . '/zen', "$ENV{HOME}/.zen";
defined $zen or die "No Zen profile directory (launch Zen once to create it)\n";

my $userjs = `curl -fsSL $source`;
$? == 0 or die "Failed to download $source\n";
$userjs =~ s/\r\n/\n/g;
my ($version) = $userjs =~ /^ \* version: (\S+)/m or die "No version in BetterZen user.js\n";

open my $overrides, '<', "$RealBin/user-overrides.js" or die "user-overrides.js: $!\n";
my $mine = do { local $/; <$overrides> };
close $overrides;
$userjs =~ s/\Q$marker\E/$marker$mine/ or die "Overrides marker not found in BetterZen $version\n";

open my $out, '>', "$RealBin/user.js" or die "user.js: $!\n";
print $out $userjs;
close $out or die "user.js: $!\n";
print "build user.js from BetterZen $version\n";

open my $installs, '<', "$zen/installs.ini" or die "$zen/installs.ini: $! (launch Zen once to create its profile)\n";
my ($profile) = map { /^Default=(.+)$/ ? $1 : () } <$installs>;
close $installs;
defined $profile or die "No default profile in installs.ini\n";
$profile = "$zen/$profile" unless $profile =~ m{^/};

-d "$profile/chrome" or mkdir "$profile/chrome" or die "$profile/chrome: $!\n";
for my $file ('user.js', 'chrome/userChrome.css') {
  my ($name) = $file =~ m{([^/]+)$};
  my ($link, $target) = ("$profile/$file", "$RealBin/$name");
  if (-l $link && readlink($link) eq $target) {
    print "ok $link\n";
    next;
  }
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

my $quit = $^O eq 'darwin' ? 'Cmd+Q' : 'Ctrl+Q';
print "Zen is running: quit it with $quit and relaunch to apply\n" if system("pgrep -x 'zen|zen-bin' >/dev/null") == 0;
