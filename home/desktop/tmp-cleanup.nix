# Delete git repos in /tmp older than 10d (parent dir mtime).
#
# Why a separate service instead of relying on modules/cleanup.nix's
# systemd-tmpfiles "d /tmp mM:10d" rule:
#   - tmpfiles "d" cleans individual files recursively, not whole directory
#     trees as atomic units.  A git repo with mixed mtimes (old source files,
#     newer .git objects) gets partially deleted, leaving broken state.
#   - This service checks only the parent dir mtime (set at clone time) and
#     removes the entire repo or nothing — git repos are atomic analysis units.
#
# Third-party analysis workflow: clone --depth 1 to /tmp, let AI analyze,
# discard after 10d.  No permanent ~/third-party clones to maintain.
{
  pkgs,
  ...
}:
{
  systemd.user.services.tmp-git-cleanup = {
    Unit = {
      Description = "Remove git repos in /tmp older than 10 days";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'find /tmp -maxdepth 3 -name .git -type d 2>/dev/null | while IFS= read -r gitdir; do d=$(dirname \"$gitdir\"); if [ \"$(stat -c %%Y \"$d\" 2>/dev/null || echo 0)\" -lt \"$(date -d \"10 days ago\" +%%s 2>/dev/null || echo 0)\" ]; then rm -rf \"$d\" 2>/dev/null || { chmod -R u+w \"$d\" 2>/dev/null && rm -rf \"$d\"; }; fi; done'";
    };
  };
  systemd.user.timers.tmp-git-cleanup = {
    Unit = {
      Description = "Daily cleanup of old git repos from /tmp";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
