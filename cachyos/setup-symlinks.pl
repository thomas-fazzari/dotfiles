#!/usr/bin/env perl
use strict;
use warnings;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use POSIX          qw(strftime);

my $dotfiles  = abs_path("$RealBin/..");
my $timestamp = strftime('%Y%m%d-%H%M%S', localtime);

my @links = (
  ['.config/Code/User/settings.json'        => 'editors/vscode/settings.json'],
  ['.config/Code/User/keybindings.json'     => 'editors/vscode/keybindings.json'],
  ['.config/zed/settings.json'              => 'editors/zed/settings.json'],
  ['.config/zed/keymap.json'                => 'editors/zed/keymap.json'],
  ['.config/ghostty/config'                 => 'terminal/ghostty/config'],
  ['.config/btop/btop.conf'                 => 'btop/btop.conf'],
  ['.config/btop/themes/tokyonight.theme'   => 'btop/tokyonight.theme'],
  ['.config/nvim'                           => 'nvim'],
  ['.claude/CLAUDE.md'                      => 'agentic/claude/CLAUDE.md'],
  ['.claude/settings.json'                  => 'agentic/claude/settings.json'],
  ['.claude/hooks'                          => 'agentic/hooks'],
  ['.local/share/agent-hooks'               => 'agentic/hooks'],
  ['.config/mise/config.toml'               => 'mise.toml'],
  ['.config/topgrade.toml'                  => 'cachyos/topgrade.toml'],
  ['.config/environment.d/10-dotfiles.conf' => 'cachyos/environment.conf'],
  ['.bunfig.toml'                           => 'bunfig.toml'],
  ['.config/fish/config.fish'               => 'terminal/fish/config.fish'],
  ['.config/fish/functions'                 => 'terminal/fish/functions'],
  ['.config/starship.toml'                  => 'terminal/starship/starship.toml'],
  ['.gitconfig'                             => 'git/.gitconfig'],
  ['.gitignore_global'                      => 'git/.gitignore_global'],
);

for my $pair (@links) {
  my ($link, $target) = ("$ENV{HOME}/$pair->[0]", "$dotfiles/$pair->[1]");
  -e $target or die "Missing target: $target\n";

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
