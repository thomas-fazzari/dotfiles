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
my $os        = $^O eq 'darwin' ? 'macos' : 'linux';

# [link under $HOME => target in the repo]
my @common = (
  ['.config/ghostty/config.ghostty'       => 'terminal/ghostty/config'],
  ['.config/btop/btop.conf'               => 'btop/btop.conf'],
  ['.config/btop/themes/tokyonight.theme' => 'btop/tokyonight.theme'],
  ['.config/nvim'                         => 'nvim'],
  ['.config/eilmeldung/config.toml'       => 'rss/eilmeldung/config.toml'],
  ['.local/share/agent-hooks'             => 'agentic/hooks'],
  ['.config/mise/config.toml'             => 'mise.toml'],
  ['.config/mise/mise.lock'               => 'mise.lock'],
  ['.config/topgrade.toml'                => "$os/topgrade.toml"],
  ['.config/fish/config.fish'             => 'terminal/fish/config.fish'],
  ['.config/fish/functions'               => 'terminal/fish/functions'],
  ['.config/starship.toml'                => 'terminal/starship/starship.toml'],
  ['.gitconfig'                           => 'git/.gitconfig'],
  ['.gitignore_global'                    => 'git/.gitignore_global'],
  ['.perltidyrc'                          => '.perltidyrc'],
);

my %links = (
  macos => [
    ['Library/Application Support/Code/User/settings.json'    => 'vscode/settings.json'],
    ['Library/Application Support/Code/User/keybindings.json' => 'vscode/keybindings.json'],
    ['.config/aerospace/aerospace.toml'                       => 'macos/aerospace/aerospace.toml'],
    ['.config/rex/init.lua'                                   => 'terminal/rex/init.lua'],
    ['.config/stablebar'                                      => 'macos/stablebar'],
    [
      'Library/Application Support/Alfred/Alfred.alfredpreferences/preferences/features/websearch/prefs.plist' =>
        'macos/torrenting/alfred/websearch.plist'
    ],
  ],
  linux => [
    ['.config/Code/User/keybindings.json'     => 'vscode/keybindings.json'],
    ['.config/ghostty/os.ghostty'             => 'linux/ghostty.conf'],
    ['.config/environment.d/10-dotfiles.conf' => 'linux/environment.conf'],
    ['.config/niri/config.kdl'                => 'linux/niri/config.kdl'],
    ['.zshenv'                                => 'linux/zshenv'],
  ],
);

# [file under $HOME => source in the repo, rewrite of $_]: copies adapted from the macOS originals
my %rendered = (
  macos => [

    [
      'Library/LaunchAgents/local.proton-qbittorrent.plist' =>
        'macos/torrenting/launchd/local.proton-qbittorrent.plist',
      sub { }
    ],
  ],
  linux => [
    [
      '.config/Code/User/settings.json' => 'vscode/settings.json',
      sub {
        s{/Users/thomas/Library/Application Support/mbx}{$ENV{HOME}/.local/share/mbx}g;
        s{/Users/thomas}{$ENV{HOME}}g;
        s{/opt/homebrew/bin/perl}{/usr/bin/perl}g;
      }
    ],
  ],
);

my $check = @ARGV && $ARGV[0] eq '--check';
my $drift = 0;

for my $pair (@common, @{$links{$os}}) {
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
    backup($link);
  }

  make_path(dirname($link));
  symlink $target, $link or die "$link: $!\n";
  print "link $link -> $target\n";
}

for my $entry (@{$rendered{$os}}) {
  my ($file, $source, $swap) = ("$ENV{HOME}/$entry->[0]", "$dotfiles/$entry->[1]", $entry->[2]);
  local $_ = slurp($source);
  $swap->();
  next if !-l $file && -f $file && slurp($file) eq $_;

  $drift = 1;
  if ($check) {
    print -l $file ? "link instead of copy $file\n" : -e $file ? "stale $file\n" : "missing $file\n";
    next;
  }

  if    (-l $file) { unlink $file or die "$file: $!\n" }
  elsif (-e $file) { backup($file) }
  make_path(dirname($file));
  open my $out, '>', $file or die "$file: $!\n";
  print {$out} $_;
  close $out or die "$file: $!\n";
  print "render $file from $source\n";
}

exit($check && $drift ? 1 : 0);

sub backup {
  my ($path) = @_;
  rename $path, "$path.backup-$timestamp" or die "$path: $!\n";
  print "backup $path\n";
  return;
}

sub slurp {
  my ($path) = @_;
  open my $in, '<', $path or die "$path: $!\n";
  my $content = do { local $/; <$in> };
  close $in or die "$path: $!\n";
  return $content;
}
