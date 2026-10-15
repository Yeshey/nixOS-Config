# waiting on https://github.com/openclaw/openclaw/issues/20950 to stop using this hack
{ ... }:
{
  flake.modules.homeManager.openclaw =
    { config, lib, pkgs, ... }:
    let
      cfg = config.programs.openclaw;
      prefix = "nix-openclaw:";
      jobs = {
        moltbook = import ./_automations/moltbook.nix;
        litellm-maintenance = import ./_automations/litellm-maintenance.nix;
      };
      keys = lib.mapAttrsToList (name: _: prefix + name) jobs;
      register = name: job:
        let
          prompt = job.prompt + ''

            Your final summary is delivered automatically to Telegram chat ${job.telegramChatId}.
            For an urgent update while working, use message with channel telegram
            and target ${job.telegramChatId}. Do not send a duplicate final summary manually.
          '';
          args = [
            "automations" "add"
            "--declaration-key" "${prefix}${name}"
            "--name" job.name
            "--agent" job.agent
            "--cron" job.cron
            "--tz" job.timezone
            "--exact"
            "--session" job.session
            "--message" prompt
            "--tools" (lib.concatStringsSep "," job.tools)
            "--timeout-seconds" (toString job.timeoutSeconds)
            "--announce" "--channel" "telegram" "--to" job.telegramChatId
          ] ++ lib.optional (!job.enabled) "--disabled";
        in
        ''
          job_id="$(openclaw ${lib.escapeShellArgs args} | jq -er '.job.id // .id')"
          openclaw automations ${if job.enabled then "enable" else "disable"} "$job_id"
        '';
      reconcile = pkgs.writeShellApplication {
        name = "openclaw-register-automations";
        runtimeInputs = [ cfg.package pkgs.jq ];
        text = ''
          # Fail and let systemd retry while the gateway is still starting.
          openclaw automations status >/dev/null

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList register jobs)}

          # Remove only jobs owned by this module whose declarations were removed.
          stale="$(openclaw automations list --all --json | jq -r \
            --arg prefix ${lib.escapeShellArg prefix} \
            --argjson keep ${lib.escapeShellArg (builtins.toJSON keys)} '
              .jobs[]?
              | select((.declarationKey // "") | startswith($prefix))
              | select(.declarationKey as $key | ($keep | index($key)) == null)
              | .id
            ')"
          while IFS= read -r job_id; do
            if [ -n "$job_id" ]; then
              openclaw automations remove "$job_id"
            fi
          done <<< "$stale"
        '';
      };
    in
    lib.mkIf cfg.enable {
      programs.openclaw.config = {
        cron.enabled = true;
        # Named automation sessions also use the direct-chat reset policy.
        # Daily/weekly activity keeps these sessions alive; other direct chats
        # also reset after 30 idle days instead of resetting every day.
        session.resetByType.direct = {
          mode = "idle";
          idleMinutes = 43200;
        };
      };

      systemd.user.services.openclaw-automations = {
        Unit = {
          Description = "Reconcile Nix-declared OpenClaw automations";
          Requires = [ "openclaw-gateway.service" ];
          After = [ "openclaw-gateway.service" ];
          PartOf = [ "openclaw-gateway.service" ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 12;
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${reconcile}/bin/openclaw-register-automations";
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStartSec = "120s";
          Environment = [
            "HOME=${config.home.homeDirectory}"
            "OPENCLAW_STATE_DIR=${cfg.stateDir}"
            "OPENCLAW_CONFIG_PATH=${cfg.stateDir}/openclaw.json"
          ];
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
