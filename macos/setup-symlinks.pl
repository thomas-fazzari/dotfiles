#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use FindBin qw($RealBin);
use POSIX qw(strftime);

my $dotfiles = abs_path("$RealBin/..");
my $timestamp = strftime('%Y%m%d-%H%M%S', localtime);

my @links = (
    ['Library/Application Support/Code - Insiders/User/settings.json' => 'editors/vscode/settings.json'],
    ['Library/Application Support/Code - Insiders/User/keybindings.json' => 'editors/vscode/keybindings.json'],
    ['.config/aerospace/aerospace.toml' => 'aerospace/aerospace.toml'],
    ['.config/ghostty/config.ghostty' => 'ghostty/config'],
    ['.config/btop/btop.conf' => 'btop/btop.conf'],
    ['.config/btop/themes/tokyonight.theme' => 'btop/tokyonight.theme'],
    ['.config/nvim' => 'nvim'],
    ['.claude/CLAUDE.md' => 'agentic/claude/CLAUDE.md'],
    ['.claude/settings.json' => 'agentic/claude/settings.json'],
    ['.claude/hooks' => 'agentic/claude/hooks'],
    ['.config/mise/config.toml' => 'mise.toml'],
    ['.zshenv' => 'zsh/.zshenv'],
    ['.zshrc' => 'zsh/.zshrc'],
    ['.p10k.zsh' => 'zsh/.p10k.zsh'],
    ['.gitconfig' => 'git/.gitconfig'],
    ['.gitignore_global' => 'git/.gitignore_global'],
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
