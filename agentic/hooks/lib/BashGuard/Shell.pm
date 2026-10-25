package BashGuard::Shell;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
  split_commands program_positions program_name is_shell inline_script operands expand_home shell_quote
);

my %PREFIXES   = map { $_ => 1 } qw(sudo xargs env command nohup time ! { if then else elif do while until);
my %EXEC_FLAGS = map { $_ => 1 } qw(-exec -execdir -ok -okdir);
my %SHELLS     = map { $_ => 1 } qw(sh bash zsh dash ksh fish);

sub unquote {
  my ($word) = @_;
  my $text = '';
  while ($word =~ /\G(?:\\(.)|'([^']*)'|"((?:\\.|[^"\\])*)"|([^\\'"]+))/gs) {
    if    (defined $1) { $text .= $1 }
    elsif (defined $2) { $text .= $2 }
    elsif (defined $3) {
      (my $inner = $3) =~ s/\\(.)/$1/gs;
      $text .= $inner;
    }
    else { $text .= $4 }
  }
  return $text;
}

# Simple commands made of [start, end, text] words, or undef when an open quote or a heredoc makes the line unsafe to read
sub split_commands {
  my ($command) = @_;
  my @commands = ([]);
  pos($command) = 0;
  while (pos($command) < length $command) {
    next if $command =~ /\G[ \t]+/gc;
    if ($command =~ /\G[;&|()\n`]/gc) {
      push @commands, [];
      next;
    }
    next if $command =~ /\G#[^\n]*/gc;

    my $start = pos $command;
    return unless $command =~ /\G((?:\\.|'[^']*'|"(?:\\.|[^"\\])*"|[^ \t;&|()\n'"\\<`]|<(?!<))+)/gcs;
    my $word = $1;
    push @{$commands[-1]}, [$start, pos $command, unquote($word)];
    push @commands,        @{quoted_substitutions($word, $start) // return};
  }
  return [grep {@$_} @commands];
}

# Commands inside "$(...)" and "`...`", with offsets into the whole line, or undef when they nest
sub quoted_substitutions {
  my ($word, $offset) = @_;
  my @commands;
  while ($word =~ /"((?:\\.|[^"\\])*)"/g) {
    my ($quoted, $quoted_start) = ($1, $offset + $-[1]);
    while ($quoted =~ /\$\(([^()`]*)\)|`([^`]*)`/g) {
      my $inner       = $1 // $2;
      my $inner_start = $quoted_start + (defined $1 ? $-[1] : $-[2]);
      my $nested      = split_commands($inner) or return;
      push @commands, map { [map { [$_->[0] + $inner_start, $_->[1] + $inner_start, $_->[2]] } @$_] } @$nested;
    }
    (my $rest = $quoted) =~ s/\$\([^()`]*\)|`[^`]*`//g;
    return if $rest =~ /\$\(|`/;
  }
  return \@commands;
}

# Indexes of the words that name a program to run
sub program_positions {
  my @words = @_;
  my @positions;
  my $expect_program = 1;
  my $after_prefix   = 0;
  for my $index (0 .. $#words) {
    my $text = $words[$index][2];
    if ($expect_program) {
      next if $text =~ /^[A-Za-z_][A-Za-z0-9_]*=/ || ($after_prefix && $text =~ /^-/);
      push @positions, $index;
      $expect_program = $after_prefix = $PREFIXES{$text};
    }
    elsif ($EXEC_FLAGS{$text}) {
      $expect_program = 1;
    }
  }
  return @positions;
}

sub program_name {
  my ($program) = @_;
  return $program =~ s{.*/}{}r;
}

sub is_shell {
  my ($program) = @_;
  return $SHELLS{program_name($program)};
}

# Script text a shell gets through -c, or eval through its arguments
sub inline_script {
  my ($program, @args) = @_;
  return join ' ', @args if program_name($program) eq 'eval';
  return unless is_shell($program);
  while (@args && $args[0] =~ /^[-+]/) {
    my $flag = shift @args;
    return shift @args if $flag =~ /^-[a-zA-Z]*c[a-zA-Z]*$/;
    shift @args        if $flag =~ /^[-+][oO]$/;
  }
  return;
}

# Everything after -- counts, even words starting with a dash
sub operands {
  my @args = @_;
  my @operands;
  while (defined(my $arg = shift @args)) {
    return @operands, @args if $arg eq '--';
    push @operands, $arg unless $arg =~ /^-./;
  }
  return @operands;
}

sub expand_home {
  my ($path) = @_;
  return $path =~ s{^(?:~|\$HOME|\$\{HOME\})(?=/|$)}{$ENV{HOME} // ''}er;
}

sub shell_quote {
  my ($text) = @_;
  return $text if $text =~ m{^[\w@%+=:,./-]+$};
  $text =~ s/'/'\\''/g;
  return "'$text'";
}

1;
