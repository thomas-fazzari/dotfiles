#!/usr/bin/env perl
use strict;
use warnings;
use Cwd            qw(abs_path);
use File::Basename qw(basename dirname);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use POSIX          qw(strftime);

my $dotfiles  = abs_path("$RealBin/../..");
my $timestamp = strftime('%Y%m%d-%H%M%S', localtime);

my @links = (
  ['.config/Code/User/keybindings.json'          => 'vscode/keybindings.json'],
  ['.config/ghostty/config.ghostty'              => 'terminal/ghostty/config'],
  ['.config/ghostty/os.ghostty'                  => 'linux/ghostty.conf'],
  ['.config/btop/btop.conf'                      => 'btop/btop.conf'],
  ['.config/btop/themes/tokyonight.theme'        => 'btop/tokyonight.theme'],
  ['.config/nvim'                                => 'nvim'],
  ['.config/eilmeldung/config.toml'              => 'rss/eilmeldung/config.toml'],
  ['.claude/CLAUDE.md'                           => 'agentic/claude/CLAUDE.md'],
  ['.claude/settings.json'                       => 'agentic/claude/settings.json'],
  ['.claude/hooks'                               => 'agentic/hooks'],
  ['.local/share/agent-hooks'                    => 'agentic/hooks'],
  ['.local/share/applications/herdr-app.desktop' => 'linux/herdr-app.desktop'],
  ['.config/herdr-app/settings.json'             => 'agentic/herdr/app/settings.json'],
  ['.config/herdr-app/themes/tokyonight.json'    => 'agentic/herdr/app/themes/tokyonight.json'],
  ['.config/mise/config.toml'                    => 'mise.toml'],
  ['.config/mise/mise.lock'                      => 'mise.lock'],
  ['.config/topgrade.toml'                       => 'linux/topgrade.toml'],
  ['.config/environment.d/10-dotfiles.conf'      => 'linux/environment.conf'],
  ['.config/niri/config.kdl'                     => 'linux/niri/config.kdl'],
  ['.zshenv'                                     => 'linux/zshenv'],
  ['.bunfig.toml'                                => 'bunfig.toml'],
  ['.config/fish/config.fish'                    => 'terminal/fish/config.fish'],
  ['.config/fish/functions'                      => 'terminal/fish/functions'],
  ['.config/starship.toml'                       => 'terminal/starship/starship.toml'],
  ['.gitconfig'                                  => 'git/.gitconfig'],
  ['.gitignore_global'                           => 'git/.gitignore_global'],
  ['.perltidyrc'                                 => '.perltidyrc'],
);

my @rendered = (
  [
    '.config/Code/User/settings.json' => 'vscode/settings.json',
    sub {
      s{/Users/thomas/Library/Application Support/mbx}{$ENV{HOME}/.local/share/mbx}g;
      s{/Users/thomas}{$ENV{HOME}}g;
      s{/opt/homebrew/bin/perl}{/usr/bin/perl}g;
      s{wallpapers/creation-ascii\.png}{wallpapers/bridge-over-water.jpg}g;
    }
  ],
  [
    '.config/herdr-app/keys.json' => 'agentic/herdr/app/keys.json',
    sub {
      s{"cmd-}{"super-}g;
      s{"ctrl-v": "terminal.paste_image"}{"ctrl-v": "terminal.paste"};
    }
  ],
);

# Claude Code has no setting for extra skill directories
for my $skill (glob "$dotfiles/agentic/skills/*/SKILL.md") {
  my $name = basename(dirname($skill));
  push @links, [".claude/skills/$name" => "agentic/skills/$name"];
}

my $check = @ARGV && $ARGV[0] eq '--check';
my $drift = 0;

# Links left behind by renamed or deleted skills
for my $link (glob "$ENV{HOME}/.claude/skills/*") {
  next unless -l $link && !-e $link && index(readlink($link), "$dotfiles/") == 0;
  $drift = 1;
  if ($check) { print "stale $link\n"; next }
  unlink $link or die "$link: $!\n";
  print "unlink $link\n";
}

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

for my $entry (@rendered) {
  my ($file, $source, $swap) = ("$ENV{HOME}/$entry->[0]", "$dotfiles/$entry->[1]", $entry->[2]);
  local $_ = slurp($source);
  $swap->();
  next if !-l $file && -f $file && slurp($file) eq $_;

  $drift = 1;
  if ($check) { print -l $file ? "link instead of copy $file\n" : -e $file ? "stale $file\n" : "missing $file\n"; next }

  if    (-l $file) { unlink $file or die "$file: $!\n" }
  elsif (-e $file) {
    rename $file, "$file.backup-$timestamp" or die "$file: $!\n";
    print "backup $file\n";
  }
  make_path(dirname($file));
  open my $out, '>', $file or die "$file: $!\n";
  print {$out} $_;
  close $out or die "$file: $!\n";
  print "render $file from $source\n";
}

exit($check && $drift ? 1 : 0);

sub slurp {
  my ($path) = @_;
  open my $in, '<', $path or die "$path: $!\n";
  my $content = do { local $/; <$in> };
  close $in or die "$path: $!\n";
  return $content;
}
