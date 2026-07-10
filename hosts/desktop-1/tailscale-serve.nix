# Tailscale Serve: 暴露 QMD MCP 到 tailnet via HTTPS
#
# Port SSOT: home/dev/qmd.nix → custom.qmd.port
# Requires HTTPS certificates enabled in Tailscale admin console:
#   https://login.tailscale.com/admin/settings/general
# (one-time per tailnet, not nixifiable — human auth required).
#
# tailscale serve --bg stores config in tailscaled state; survives reboot.
# Idempotent re-run on every activation.
#
# Boot race: tailscaled.service reports "active" before the node
# reaches BackendState == Running (login + DERP + tailscale0 up).
# `tailscale serve` called during that window fails with
# "unexpected state: NoState". We gate on `tailscale status`
# (returns 0 only at Running), mirroring nixpkgs' own
# tailscaled-autoconnect unit. Restart=on-failure keeps retrying
# until tailscale comes up (mihomo/Tailscale boot ordering).
# Ref: https://github.com/tailscale/tailscale/issues/11504
{ config, pkgs, ... }:
let
  qmdPort = config.home-manager.users.fugui.custom.qmd.port;
in
{
  systemd.services.tailscale-serve-qmd = {
    description = "Tailscale Serve for QMD MCP (port SSOT: home/dev/qmd.nix → custom.qmd.port)";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      for i in $(seq 1 60); do
        if tailscale status --peers=false >/dev/null 2>&1; then
          exec tailscale serve --bg localhost:${toString qmdPort}
        fi
        sleep 1
      done
      echo "tailscale not online after 60s; will retry" >&2
      exit 1
    '';
  };
}
