#!/usr/bin/env perl
use strict;
use warnings;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use POSIX          qw(strftime);

my $dotfiles  = abs_path("$RealBin/../..");
my $timestamp = strftime('%Y%m%d-%H%M%S', localtime);

my @links = (
  ['Library/Application Support/Code/User/settings.json'    => 'vscode/settings.json'],
  ['Library/Application Support/Code/User/keybindings.json' => 'vscode/keybindings.json'],
  ['.config/aerospace/aerospace.toml'                       => 'macos/aerospace/aerospace.toml'],
  ['.config/ghostty/config.ghostty'                         => 'terminal/ghostty/config'],
  ['.config/btop/btop.conf'                                 => 'btop/btop.conf'],
  ['.config/btop/themes/tokyonight.theme'                   => 'btop/tokyonight.theme'],
  ['.config/nvim'                                           => 'nvim'],
  ['.config/eilmeldung/config.toml'                         => 'rss/eilmeldung/config.toml'],
  ['.local/share/agent-hooks'                               => 'agentic/hooks'],
  ['.config/herdr-app/settings.json'                        => 'agentic/herdr/app/settings.json'],
  ['.config/herdr-app/keys.json'                            => 'agentic/herdr/app/keys.json'],
  ['.config/herdr-app/themes/tokyonight.json'               => 'agentic/herdr/app/themes/tokyonight.json'],
  ['.config/mise/config.toml'                               => 'mise.toml'],
  ['.config/mise/mise.lock'                                 => 'mise.lock'],
  ['.config/topgrade.toml'                                  => 'macos/topgrade.toml'],
  ['.bunfig.toml'                                           => 'bunfig.toml'],
  ['.config/fish/config.fish'                               => 'terminal/fish/config.fish'],
  ['.config/fish/functions'                                 => 'terminal/fish/functions'],
  ['.config/starship.toml'                                  => 'terminal/starship/starship.toml'],
  ['.gitconfig'                                             => 'git/.gitconfig'],
  ['.gitignore_global'                                      => 'git/.gitignore_global'],
  ['.perltidyrc'                                            => '.perltidyrc'],
);

my $check = @ARGV && $ARGV[0] eq '--check';
my $drift = 0;

for my $pair (@links) {
  my ($link, $target) = ("$ENV{HOME}/$pair->[0]", "$dotfiles/$pair->[1]");
  -e $target or die "Missing target: $target\n";

  if ($check) {
    next if -l $link && readlink($link) eq $target;
    $drift = 1;
    print -l $link ? "wrong $link -> " . readlink($link) . "\n" : -e $link ? "not a link $link\n" : "missing $link\n";
    next;
  }

  if (-l $link) {
    next if readlink($link) eq $target;
    unlink $link or die "$link: $!\n";
  }
  elsif (-e $link) {
    rename $link, "$link.backup-$timestamp" or die "$link: $!\n";
    print "backup $link\n";
  }

  make_path(dirname($link));
  symlink $target, $link or die "$link: $!\n";
  print "link $link -> $target\n";
}

exit($check && $drift ? 1 : 0);
