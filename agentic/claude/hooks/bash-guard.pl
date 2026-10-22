#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use JSON::PP;
use lib "$RealBin/lib";
use BashGuard::Git     qw(git_risk);
use BashGuard::Install qw(install_risk);
use BashGuard::Shell   qw(split_commands program_positions);
use BashGuard::Trash   qw(is_rm trash_available rewrite_rm deletion_risk);

my $tool_input = decode_json( do { local $/; <> } )->{tool_input} // {};
my $command    = $tool_input->{command}                           // '';
my $commands   = split_commands($command) or exit 0;

my ( @risks, @rm_words );
for my $words (@$commands) {
    for my $position ( program_positions(@$words) ) {
        my ( $program, @args ) =
          map { $_->[2] } @{$words}[ $position .. $#$words ];
        push @risks,    git_risk(@args) if $program eq 'git';
        push @risks,    install_risk( $program, @args );
        push @risks,    deletion_risk( $program, @args );
        push @rm_words, $words->[$position] if is_rm($program);
    }
}
@rm_words = () unless trash_available();

my %output;
$output{updatedInput} =
  { %$tool_input, command => rewrite_rm( $command, @rm_words ) }
  if @rm_words;

if (@risks) {
    $output{permissionDecision}       = 'ask';
    $output{permissionDecisionReason} = join( '. ', @risks ) . '.';
}

# Lone rm is approved here
# Anything chained to it keeps its normal permission check
elsif (@rm_words
    && @$commands == 1
    && is_rm( $commands->[0][0][2] )
    && $command !~ /[\$`<>]/ )
{
    $output{permissionDecision}       = 'allow';
    $output{permissionDecisionReason} = 'rm moves files to the trash';
}

print encode_json(
    { hookSpecificOutput => { hookEventName => 'PreToolUse', %output } } )
  if %output;
