package BashGuard::Shell;
use strict;
use warnings;
use Exporter 'import';
use Hash::Util::FieldHash qw(fieldhash);

our @EXPORT_OK = qw(
  split_commands is_piped program_positions program_name is_shell inline_script operands expand_home shell_quote
);

# Commands that read the output of the command before them through a pipe
fieldhash my %PIPED;

my %PREFIXES   = map { $_ => 1 } qw(sudo xargs env command nohup time ! { if then else elif do while until);
my %EXEC_FLAGS = map { $_ => 1 } qw(-exec -execdir);
my %SHELLS     = map { $_ => 1 } qw(sh bash zsh fish);
my $DELIMITER  = qr/(?:\\.|'[^']*'|"[^"]*"|[^\s;&|()<>'"\\`])+/s;

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

# Simple commands made of [start, end, text] words, or undef when an open quote makes the line unsafe to read
#
# Heredoc bodies are skipped, commands substituted inside "..." join the list
sub split_commands {
  my ($command) = @_;
  my $state = {commands => [], heredocs => []};
  pos($command) = 0;
  parse_commands(\$command, $state) // return;
  return [grep {@$_} @{$state->{commands}}];
}

sub is_piped {
  my ($words) = @_;
  return $PIPED{$words};
}

# Reads commands up to the end of the input, or up to the ) or ` that closes a substitution
sub parse_commands {
  my ($input, $state, $terminator) = @_;
  my $words = [];
  my $depth = 0;
  push @{$state->{commands}}, $words;
  while (pos($$input) < length $$input) {
    next if $$input =~ /\G[ \t]+/gc || $$input =~ /\G#[^\n]*/gc;
    if ($$input =~ /\G([;&|()\n`])/gc) {
      my $separator = $1;
      if    ($separator eq '(')                 { $depth++ }
      elsif ($separator eq ')' && $depth)       { $depth-- }
      elsif ($separator eq ($terminator // '')) { return 1 }
      skip_heredocs($input, $state) if $separator eq "\n";

      # || chains on failure and pipes nothing, |& pipes stderr too
      my $piped = $separator eq '|' && !($$input =~ /\G\|/gc);
      $$input =~ /\G&/gc if $piped;
      push @{$state->{commands}}, $words = [];
      $PIPED{$words} = 1 if $piped;
      next;
    }
    if ($$input =~ /\G<<[ \t]*($DELIMITER)/gc) {
      push @{$state->{heredocs}}, unquote($1);
      next;
    }
    push @$words, parse_word($input, $state) // return;
  }
  return defined $terminator ? undef : 1;
}

sub parse_word {
  my ($input, $state) = @_;
  my $start = pos $$input;
  my $text  = '';
  while (1) {
    if    ($$input =~ /\G\\(.)/gcs)    { $text .= $1 }
    elsif ($$input =~ /\G'([^']*)'/gc) { $text .= $1 }
    elsif ($$input =~ /\G"/gc) {
      my $from = pos $$input;
      quoted_substitutions($input, $state) // return;
      $text .= substr($$input, $from, pos($$input) - $from - 1) =~ s/\\(.)/$1/gsr;
    }
    elsif ($$input =~ /\G([^ \t;&|()\n'"\\<`]+|<<<|<(?!<))/gc) { $text .= $1 }
    else                                                       {last}
  }
  return pos($$input) > $start ? [$start, pos $$input, $text] : undef;
}

# Reads the commands that $(...) and `...` run inside "..." up to its closing quote
sub quoted_substitutions {
  my ($input, $state) = @_;
  while (pos($$input) < length $$input) {
    return 1 if $$input =~ /\G"/gc;
    if    ($$input =~ /\G\$\(/gc) { parse_commands($input, $state, ')') // return }
    elsif ($$input =~ /\G`/gc)    { parse_commands($input, $state, '`') // return }
    else                          { $$input =~ /\G(?:\\.|[^"\\\$`]+|\$)/gcs }
  }
  return;
}

# A heredoc body runs from the line after its operator to the delimiter line
sub skip_heredocs {
  my ($input, $state) = @_;
  while (defined(my $delimiter = shift @{$state->{heredocs}})) {
    while (pos($$input) < length $$input) {
      $$input =~ /\G([^\n]*)\n?/gc;
      last if $1 eq $delimiter;
    }
  }
  return;
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
