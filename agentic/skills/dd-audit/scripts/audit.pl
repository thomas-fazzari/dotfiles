#!/usr/bin/env perl
# Read-only report of reclaimable disk space, broken dotfile links and system health
use strict;
use warnings;
use Cwd        qw(abs_path);
use FindBin    qw($RealBin);
use IPC::Open3 qw(open3);
use JSON::PP   qw(decode_json);

my $dotfiles   = abs_path("$RealBin/../../../..");
my $home       = $ENV{HOME};
my $dev        = "$home/Dev";
my $sweep_days = 15;

# Small caches are not worth a line
my $min_cache_kib = 100 * 1024;

# Output lines of a command, stderr included (mise reports on stderr)
sub run {
  my (@cmd) = @_;
  my $pid = open3(my $in, my $out, undef, @cmd);
  close $in;
  chomp(my @lines = <$out>);
  waitpid $pid, 0;
  return @lines;
}

sub succeeds {
  my (@cmd) = @_;
  run(@cmd);
  return $? == 0;
}

sub kib_of {
  my (@paths) = @_;
  @paths = grep {-e} @paths;
  return 0 unless @paths;
  my $total = 0;
  $total += (split /\s+/)[0] for run('du', '-sk', @paths);
  return $total;
}

sub human {
  my ($kib) = @_;
  my @units = qw(K M G T);
  my $i     = 0;
  while ($kib >= 1024 && $i < $#units) { $kib /= 1024; $i++ }
  return sprintf '%.1f%s', $kib, $units[$i];
}

sub tilde {
  my ($path) = @_;
  return $path =~ s/^\Q$home\E/~/r;
}

sub item {
  my ($kib, $label, $cmd) = @_;
  printf "  %8s  %s\n", defined $kib ? human($kib) : '', $label;
  printf "            apply: %s\n", $cmd if $cmd;
  return;
}

sub section {
  my ($title) = @_;
  print "\n## $title\n";
  return;
}

sub disk_usage {
  my ($line) = grep {/Data$/} run('df', '-k', '/System/Volumes/Data');
  my (undef, $size, $used) = split /\s+/, $line // '';
  printf "Data volume: %s used of %s\n", human($used), human($size) if $size;
  return;
}

# Reclaimable size per target directory, from a cargo sweep dry run
sub sweepable {
  my (@criteria) = @_;
  my %size;
  for (run('cargo', 'sweep', '--dry-run', @criteria, '--recursive', $dev)) {
    $size{$2} = $1 if /Would clean: (.+?) from "(.+)"/ && $1 ne 'nothing';
  }
  return \%size;
}

sub rust_artifacts {
  section('Rust build artifacts');
  my $old_toolchains = sweepable('--installed');
  my $old            = sweepable('--time', $sweep_days);
  for my $target (run('fd', '-u', '-t', 'd', '-d', 4, '--prune', '^target$', $dev)) {
    $target =~ s{/$}{};
    next unless -e "$target/CACHEDIR.TAG";
    item(kib_of($target), tilde($target));
    item(undef, "built by uninstalled toolchains: $old_toolchains->{$target}") if $old_toolchains->{$target};
    item(undef, "unused for $sweep_days days: $old->{$target}")                if $old->{$target};

    # cargo sweep leaves incremental caches alone
    # rustc only reuses the latest ones
    my @roots       = glob "$target/*/incremental";
    my @incremental = @roots ? run('find', @roots, qw(-maxdepth 1 -mindepth 1 -type d -mtime), "+$sweep_days") : ();
    item(
      kib_of(@incremental),
      "incremental caches untouched for $sweep_days days",
      "find $target/*/incremental -maxdepth 1 -mindepth 1 -type d -mtime +$sweep_days -exec rm -r {} +"
    ) if @incremental;
  }
  item(undef, 'Artifacts from uninstalled toolchains', 'cargo sweep --installed --recursive ~/Dev')
    if %{$old_toolchains};
  item(undef, "Artifacts unused for $sweep_days days", "cargo sweep --time $sweep_days --recursive ~/Dev") if %{$old};
  return;
}

sub rust_toolchains {
  section('Rust toolchains');
  my %pinned;
  for my $file (run('fd', '-u', '-d', 4, '^rust-toolchain(\.toml)?$', $dev)) {
    open my $fh, '<', $file or next;
    my $text = do { local $/ = undef; <$fh> };
    close $fh;
    my ($channel) = $text =~ /channel\s*=\s*"([^"]+)"/ ? $1 : $text =~ /^\s*(\S+)/;
    push @{$pinned{$channel}}, tilde($file =~ s{/[^/]+$}{}r) if $channel;
  }
  for (run('rustup', 'toolchain', 'list')) {
    my ($name)  = /^(\S+)/ or next;
    my $channel = $name =~ s/-\w+-apple-darwin\z//r;
    if    (/\(.*default.*\)/) { item(undef, "$name (default)") }
    elsif ($pinned{$channel}) { item(undef, "$name (pinned by " . join(', ', @{$pinned{$channel}}) . ')') }
    else                      { item(undef, "$name (unused)", "rustup toolchain uninstall $name") }
  }
  return;
}

sub package_caches {
  section('Package caches');
  my @caches = (
    ['NuGet', ["$home/.nuget/packages", "$home/.local/share/NuGet/http-cache"], 'dotnet nuget locals all --clear'],
    ['uv',    ["$home/.cache/uv"],                                              'uv cache prune'],
    ['bun',   ["$home/.bun/install/cache"],                                     'bun pm cache rm'],
    ['npm',   ["$home/.npm"],                                                   'npm cache clean --force'],
  );
  my $shown = 0;
  for my $cache (@caches) {
    my ($label, $paths, $cmd) = @{$cache};
    my $kib = kib_of(@{$paths});
    next if $kib < $min_cache_kib;
    item($kib, $label, $cmd);
    $shown++;
  }
  item(undef, 'Nothing worth clearing') unless $shown;
  return;
}

sub mise_versions {
  section('mise');
  my @prunable = map { /^mise (\S+) is prunable/ ? $1 : () } run('mise', 'prune', '--dry-run');
  if (@prunable) { item(undef, "Unused tool versions: @prunable", 'mise prune') }
  else           { item(undef, 'No unused tool versions') }
  return;
}

sub docker {
  section('Docker');
  my $kib = kib_of("$home/Library/Containers/com.docker.docker");
  if (succeeds('docker', 'info')) {
    item($kib, 'Docker Desktop data');
    print "            $_\n" for run('docker', 'system', 'df');
    item(undef, 'Stopped containers, dangling images, unused networks and build cache', 'docker system prune');
  }
  elsif ($kib) {
    item($kib, 'Docker Desktop data (daemon not running; start Docker to inspect)');
  }
  return;
}

sub pi_sessions {
  section('Pi sessions');
  my ($summary) = reverse run("$dotfiles/agentic/pi-config/scripts/prune-sessions.pl", '--dry-run');
  my $cmd = $summary =~ /^Would trash [1-9]/ ? 'mise -C ~/Dev/dotfiles/agentic/pi-config run sessions:prune' : undef;
  item(kib_of("$home/.pi/agent/sessions"), $summary, $cmd);
  return;
}

sub dotfile_links {
  section('Dotfile links');
  my @broken = run("$dotfiles/macos/scripts/setup-symlinks.pl", '--check');
  item(undef, $_, 'mise -C ~/Dev/dotfiles run symlinks') for @broken;
  item(undef, 'All linked') unless @broken;
  return;
}

sub launch_jobs {
  section('Launch agents and daemons');
  for my $dir ("$home/Library/LaunchAgents", '/Library/LaunchAgents', '/Library/LaunchDaemons') {
    for my $plist (glob "$dir/*.plist") {
      my $job     = eval { decode_json(join "\n", run('plutil', '-convert', 'json', '-o', '-', $plist)) } or next;
      my $program = $job->{Program} // ($job->{ProgramArguments} // [])->[0] // '?';
      my $status  = -e $program ? '' : ' (program missing)';
      item(undef, tilde($plist) . ' -> ' . tilde($program) . $status);
    }
  }
  return;
}

sub health {
  section('Health');
  item(undef, (run(@{$_}))[0])
    for ['fdesetup', 'status'], ['/usr/libexec/ApplicationFirewall/socketfilterfw', '--getglobalstate'],
    ['csrutil', 'status'];
  return;
}

print "# Daily driver audit\n";
disk_usage();
rust_artifacts();
rust_toolchains();
package_caches();
mise_versions();
docker();
pi_sessions();
dotfile_links();
launch_jobs();
health();
