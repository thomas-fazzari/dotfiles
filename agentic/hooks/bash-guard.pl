#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use JSON::PP;
use List::Util qw(uniq);
use lib "$RealBin/lib";
use BashGuard::Delete  qw(deletion_risk);
use BashGuard::Git     qw(git_risk);
use BashGuard::Install qw(install_risk);
use BashGuard::Remote  qw(is_fetcher runs_unseen_code);
use BashGuard::Secret  qw(secret_risk);
use BashGuard::Shell   qw(split_commands program_positions program_name inline_script);
use BashGuard::Trash   qw(is_rm trash_available rewrite_rm);

# bash -c nested deeper than this goes unchecked
my $MAX_NESTING = 3;

my $tool_input = decode_json(do { local $/; <> })->{tool_input} // {};
my $command    = $tool_input->{command}                         // '';
my $commands   = split_commands($command) or exit 0;

my (@risks, @rm_words, $fetches, $runs_unseen_code);

sub inspect {
  my ($commands, $depth) = @_;
  for my $words (@$commands) {
    for my $position (program_positions(@$words)) {
      my ($program, @args) = map { $_->[2] } @{$words}[$position .. $#$words];
      push @risks, git_risk(@args) if program_name($program) eq 'git';
      push @risks, install_risk($program, @args);
      push @risks, deletion_risk($program, @args);
      push @risks, secret_risk(@args);
      $fetches          ||= is_fetcher($program);
      $runs_unseen_code ||= runs_unseen_code($program, @args);

      # Nested scripts carry no offsets into the command line, so the rewrite only reaches top-level rm
      push @rm_words, $words->[$position] if $depth == 0 && is_rm($program);

      my $script = inline_script($program, @args);
      my $nested = defined $script && $depth < $MAX_NESTING && split_commands($script);
      inspect($nested, $depth + 1) if $nested;
    }
  }
  return;
}
inspect($commands, 0);
push @risks, 'running code fetched from the network skips any review' if $fetches && $runs_unseen_code;
@risks    = uniq @risks;
@rm_words = () unless trash_available();

my %output;
$output{updatedInput} = {%$tool_input, command => rewrite_rm($command, @rm_words)} if @rm_words;

if (@risks) {
  $output{permissionDecision}       = 'ask';
  $output{permissionDecisionReason} = join('. ', @risks) . '.';
}

# Lone rm is approved here
# Anything chained to it keeps its normal permission check
elsif (@rm_words && @$commands == 1 && is_rm($commands->[0][0][2]) && $command !~ /[\$`<>]/) {
  $output{permissionDecision}       = 'allow';
  $output{permissionDecisionReason} = 'rm moves files to the trash';
}

print encode_json({hookSpecificOutput => {hookEventName => 'PreToolUse', %output}}) if %output;
