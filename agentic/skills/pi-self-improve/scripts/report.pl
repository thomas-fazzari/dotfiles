#!/usr/bin/env perl
# Read-only report of Pi's cost, model requests, tools and tool failures.
# Data comes from my pi-otlp extension (https://github.com/thomas-fazzari/pi-otlp), which sends Pi's telemetry to a local Grafana.
use strict;
use warnings;
use FindBin      qw($RealBin);
use Getopt::Long qw(GetOptions);
use HTTP::Tiny;
use JSON::PP   qw(decode_json);
use List::Util qw(sum0);
use Time::Piece;

my $grafana  = $ENV{GRAFANA_URL} // 'http://127.0.0.1:3000';
my $logbook  = "$RealBin/../logbook.md";
my $sessions = "$ENV{HOME}/.pi/agent/sessions";

# Prometheus keeps a year of samples (see LGTM_RETENTION, pi-otlp), Loki refuses a range > 30 days
my $all_days  = 365;
my $loki_days = 30;
my $day       = 86_400;

my ($since, $all, $mark_run);
my $top = 12;
GetOptions('since=s' => \$since, 'all' => \$all, 'mark-run' => \$mark_run, 'top=i' => \$top)
  or die "Usage: report.pl [--since YYYY-MM-DD | --all] [--top N] | --mark-run\n";

if ($mark_run) {
  mark_run();
  exit;
}

my $now = time;
my ($start, $origin) = window_start();
my $window = $now - $start;
die "The window is shorter than a minute.\n" if $window < 60;

my $http = HTTP::Tiny->new(timeout => 30);
my $json = JSON::PP->new->canonical;
my (%values, %formats);

report_window();
report_cost();
report_requests();
report_tools();
report_events();
report_failures();
report_tracked();

sub parse_time {
  my ($text) = @_;
  my ($date, $time) = $text =~ /^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2}:\d{2}))?/
    or die "Unreadable date: $text. Use YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ.\n";
  return Time::Piece->strptime("$date " . ($time // '00:00:00'), '%Y-%m-%d %H:%M:%S')->epoch;
}

sub iso {
  my ($epoch) = @_;
  return gmtime($epoch)->strftime('%Y-%m-%dT%H:%M:%SZ');
}

sub read_logbook {
  open my $fh, '<', $logbook or return '';
  my $text = do { local $/; <$fh> };
  close $fh;
  return $text;
}

sub window_start {
  return (parse_time($since), '--since') if defined $since;
  my ($last) = read_logbook() =~ /^Last run: (\S+)$/m;
  return (parse_time($last),       'the last run') if $last && !$all;
  return ($now - $all_days * $day, 'all data');
}

sub mark_run {
  my $stamp = iso(time);
  my $text  = read_logbook() || "# pi-self-improve logbook\n\nLast run:\n\n## Changes\n";
  $text =~ s/^Last run:.*$/Last run: $stamp/m;
  open my $fh, '>', $logbook or die "$logbook: $!\n";
  print {$fh} $text;
  close $fh;
  print "Last run: $stamp\n";
  return;
}

sub query {
  my ($datasource, $path, $expr) = @_;
  my $res = $http->get(
    "$grafana/api/datasources/proxy/uid/$datasource$path?" . $http->www_form_urlencode({query => $expr, time => $now}));
  die "Grafana did not answer at $grafana ($res->{status}). Start it with `mise run lgtm` in a pi-otlp clone.\n"
    unless $res->{success};
  my $body = decode_json($res->{content});
  die "$datasource refused a query: $body->{error}\n" unless $body->{status} eq 'success';
  return map { [$_->{metric}, $_->{value}[1]] } @{$body->{data}{result}};
}

sub prom {
  my ($expr) = @_;
  return query('prometheus', '/api/v1/query', $expr);
}

# The exact increase of every series over the window: each Pi process starts its series at zero, so the value
# before the window, or the first value inside it for a new series, is the baseline. No extrapolation.
sub increase {
  my ($selector, $by) = @_;
  my $w = "${window}s";
  my $inner
    = "last_over_time($selector\[$w\]) - (last_over_time($selector\[$w\] offset $w) or min_over_time($selector\[$w\]))";
  return $by ? "sum by ($by) ($inner)" : "sum($inner)";
}

# Series without the label, such as compaction cost without a model, count under "none"
sub by_label {
  my ($expr, $label) = @_;
  my %result;
  $result{$_->[0]{$label} // 'none'} += $_->[1] for prom($expr);
  return %result;
}

sub total {
  my ($expr) = @_;
  return sum0(map { $_->[1] } prom($expr));
}

sub put {
  my ($key, $value, $format) = @_;
  $values{$key}  = $value;
  $formats{$key} = $format;
  printf "  %-46s %s\n", $key, format_value($value, $format);
  return;
}

# histogram_quantile returns NaN for a histogram without samples
sub format_value {
  my ($value, $format) = @_;
  $format //= 'count';
  return 'n/a' if !defined $value || $value eq 'NaN';
  return sprintf '$%.2f',  $value       if $format eq 'usd';
  return sprintf '%.1f%%', 100 * $value if $format eq 'ratio';
  return sprintf '%.1fs',  $value       if $format eq 'seconds';
  return sprintf '%.0f',   $value;
}

sub section {
  my ($title) = @_;
  print "\n## $title\n";
  return;
}

sub sorted_desc {
  my (%by) = @_;
  my @keys = sort { $by{$b} <=> $by{$a} || $a cmp $b } keys %by;
  return @keys;
}

sub report_window {
  section('Window');
  printf "  %s to %s (%dd %dh, from %s)\n", iso($start), iso($now), $window / $day, ($window % $day) / 3600, $origin;
  return;
}

sub report_cost {
  section('Cost and tokens');
  my $cost = 'pi_cost_USD_total{service_name="pi"}';
  put('cost.total', total(increase($cost)), 'usd');
  my %model = by_label(increase($cost, 'gen_ai_request_model'), 'gen_ai_request_model');
  put("cost.model.$_", $model{$_}, 'usd') for sorted_desc(%model);
  my %kind = by_label(increase($cost, 'pi_request_kind'), 'pi_request_kind');
  put("cost.request_kind.$_", $kind{$_}, 'usd') for sorted_desc(%kind);

  # Main sessions have no agent name
  my %session;
  for (prom(increase($cost, 'pi_session_kind, gen_ai_agent_name'))) {
    my ($labels, $value) = @$_;
    $session{join '.', grep {defined} $labels->{pi_session_kind}, $labels->{gen_ai_agent_name}} += $value;
  }
  put("cost.session.$_", $session{$_}, 'usd') for sorted_desc(%session);

  my %tokens = by_label(increase('pi_token_usage_total{service_name="pi"}', 'gen_ai_token_type'), 'gen_ai_token_type');
  put("tokens.$_", $tokens{$_}) for sorted_desc(%tokens);
  my $input = sum0(map { $tokens{$_} // 0 } qw(input cache_read cache_write cache_write_1h));
  put('cache.hit_ratio', $input ? ($tokens{cache_read} // 0) / $input : undef, 'ratio');
  return;
}

sub report_requests {
  section('Model requests');
  my $count    = 'gen_ai_client_operation_duration_seconds_count{service_name="pi"';
  my %requests = by_label(increase("$count}",                       'gen_ai_request_model'), 'gen_ai_request_model');
  my %failed   = by_label(increase("$count, error_type=\"error\"}", 'gen_ai_request_model'), 'gen_ai_request_model');
  for my $model (sorted_desc(%requests)) {
    put("requests.$model",        $requests{$model});
    put("requests.failed.$model", $failed{$model} // 0);
    my $bucket
      = "gen_ai_client_operation_duration_seconds_bucket{service_name=\"pi\", gen_ai_request_model=\"$model\"}";
    for my $q (qw(0.5 0.9)) {
      put('latency.p' . ($q * 100) . ".$model",
        total("histogram_quantile($q, " . increase($bucket, 'le') . ')'), 'seconds');
    }
  }
  put('requests.aborted', total(increase("$count, pi_stop_reason=\"aborted\"}")));
  return;
}

sub report_tools {
  section('Tools');
  print "  Keys: tools.<tool>.<column>. error_rate counts both tool_error and not_run.\n";
  my %calls = by_label(increase('pi_tool_calls_total{service_name="pi"}', 'gen_ai_tool_name'), 'gen_ai_tool_name');
  my (%errors, %failed);
  for (prom(increase('pi_tool_calls_total{service_name="pi", error_type!=""}', 'gen_ai_tool_name, error_type'))) {
    my ($labels, $value) = @$_;
    $errors{$labels->{gen_ai_tool_name}}{$labels->{error_type}} = $value;
    $failed{$labels->{gen_ai_tool_name}} += $value;
  }
  my %p90 = by_label(
    'histogram_quantile(0.9, '
      . increase('pi_tool_duration_seconds_bucket{service_name="pi"}', 'le, gen_ai_tool_name') . ')',
    'gen_ai_tool_name'
  );

  printf "  %-24s %7s %10s %8s %10s %8s\n", qw(tool calls tool_error not_run error_rate p90);
  for my $tool (sort { ($failed{$b} // 0) <=> ($failed{$a} // 0) || $calls{$b} <=> $calls{$a} } keys %calls) {
    my %row = (
      calls      => $calls{$tool},
      tool_error => $errors{$tool}{tool_error} // 0,
      not_run    => $errors{$tool}{not_run}    // 0,
      error_rate => ($failed{$tool} // 0) / $calls{$tool},
      p90        => $p90{$tool},
    );
    $values{"tools.$tool.$_"}          = $row{$_} for keys %row;
    $formats{"tools.$tool.error_rate"} = 'ratio';
    $formats{"tools.$tool.p90"}        = 'seconds';
    printf "  %-24s %7s %10s %8s %10s %8s\n", $tool, format_value($row{calls}), format_value($row{tool_error}),
      format_value($row{not_run}), format_value($row{error_rate}, 'ratio'), format_value($row{p90}, 'seconds');
  }
  return;
}

sub report_events {
  section('Events');
  my $w = "${window}s";
  if ($window > $loki_days * $day) {
    $w = "${loki_days}d";
    print "  Loki counts only the last $loki_days days.\n";
  }
  my %bodies = (
    'events.sessions'          => 'Session started',
    'events.compaction'        => 'Context compacted',
    'events.compaction_failed' => 'Context compaction failed',
    'events.request_failed'    => 'Model request failed',
    'events.model_select'      => 'Model selected',
  );
  for my $key (sort keys %bodies) {
    my $expr = qq{sum(count_over_time({service_name="pi"} |= "$bodies{$key}" [$w]))};
    put($key, sum0(map { $_->[1] } query('loki', '/loki/api/v1/query', $expr)));
  }
  return;
}

sub report_tracked {
  my @changes = read_logbook() =~ /^- (\S+) \| (\S+) \| before: (\S+) \| (.+)$/mg;
  return unless @changes;
  section('Tracked changes');
  printf "  %-10s %-40s %10s %10s  %s\n", qw(date key before now change);
  while (my ($date, $key, $before, $change) = splice @changes, 0, 4) {

    # A tool without failures in the window has no failures key
    $values{$key} //= 0 if $key =~ /^failures\./;

    printf "  %-10s %-40s %10s %10s  %s\n", $date, $key, $before,
      exists $values{$key} ? format_value($values{$key}, $formats{$key}) : 'no data', $change;
  }
  return;
}

# Groups failures that differ only by numbers or file names
sub signature {
  my ($text) = @_;
  my $first = (split /\n/, $text)[0] // '';
  $first =~ s/\s+/ /g;
  $first =~ s{[\w./~-]+\.\w{1,6}\b}{<file>}g;
  $first =~ s/\d+/N/g;
  return substr $first, 0, 140;
}

sub lines_of {
  my ($file) = @_;
  open my $fh, '<', $file or die "$file: $!\n";
  my @lines = <$fh>;
  close $fh;
  return @lines;
}

sub report_failures {
  section('Tool failures in the sessions');
  my %groups;
  my @files = grep { (stat)[9] >= $start } glob "$sessions/*/*.jsonl";
  for my $file (@files) {
    my %arguments;
    for my $line (lines_of($file)) {

      # The last line of an active session can be half written
      my $entry = eval { decode_json($line) } or next;

      # Test runs of Pi, such as pi-otlp's e2e, work in temporary directories
      last if $entry->{type} eq 'session' && $entry->{cwd} =~ m{^/(?:private/)?(?:var/folders|tmp)/};
      my $message = $entry->{message} or next;
      if ($message->{role} eq 'assistant') {
        $arguments{$_->{id}} = $_->{arguments} for grep { $_->{type} eq 'toolCall' } @{$message->{content}};
        next;
      }
      next unless $message->{role} eq 'toolResult' && $message->{isError} && parse_time($entry->{timestamp}) >= $start;
      my $text      = join ' ', map { $_->{text} } grep { $_->{type} eq 'text' } @{$message->{content}};
      my $signature = signature($text);
      my $group     = $groups{"$message->{toolName}\t$signature"}
        //= {tool => $message->{toolName}, signature => $signature, count => 0, files => {}};
      $group->{count}++;
      $group->{files}{$file} = 1;
      $group->{example} //= {arguments => $arguments{$message->{toolCallId}}, file => $file};
    }
  }
  my @groups = sort { $b->{count} <=> $a->{count} } values %groups;
  printf "  %d failed tool calls in %d groups, from %d session files.\n", sum0(map { $_->{count} } @groups),
    scalar @groups, scalar @files;

  # Calls to a tool that does not exist, such as powershell, reach the sessions but not the metrics
  my %by_tool;
  $by_tool{$_->{tool}} += $_->{count} for @groups;
  put("failures.$_", $by_tool{$_}) for sorted_desc(%by_tool);

  $#groups = $top - 1 if @groups > $top;
  for my $group (@groups) {
    my $example = $json->encode($group->{example}{arguments});
    $example = substr($example, 0, 157) . '...' if length $example > 160;
    printf "\n  %dx %s, in %d sessions: %s\n", $group->{count}, $group->{tool}, scalar keys %{$group->{files}},
      $group->{signature};
    printf "     example: %s\n     session: %s\n", $example, $group->{example}{file} =~ s/^\Q$ENV{HOME}\E/~/r;
  }
  return;
}
