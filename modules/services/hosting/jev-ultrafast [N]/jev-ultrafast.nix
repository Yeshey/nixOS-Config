{ inputs, ... }:
{
  flake.modules.nixos.jev-ultrafast =
    { config, pkgs, ... }:
    let
      inherit (pkgs) lib;

      cdpPort = 9222;
      inspectorPort = 8766;

      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = inputs.jev-ultrafast;
      };

      pythonBase = pkgs.callPackage inputs.pyproject-nix.build.packages {
        python = pkgs.python312;
      };

      lockedPackages = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      patches = final: prev: {
        jev-ultrafast = prev.jev-ultrafast.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace jev_ultrafast/model.py \
              --replace-fail \
                '"https://api.typesafe.ai/v1/systemone"' \
                '"https://api.openjev.sh/v1/systemone"'

            substituteInPlace jev_ultrafast/model.py \
              --replace-fail \
                'f"Model provider returned HTTP {response.status_code}; no action executed."' \
                'f"Model provider {url} returned HTTP {response.status_code}; no action executed."'

            substituteInPlace jev_ultrafast/browser.py \
              --replace-fail \
                'url="about:blank", background=True' \
                'url="about:blank", background=False'

            substituteInPlace jev_ultrafast/browser.py \
              --replace-fail \
                'info["screenshot"] = call("Page.captureScreenshot", format="jpeg", quality=72)["data"]' \
                'info["screenshot"] = cdp("Page.captureScreenshot", session_id=session, _response_timeout=30, format="jpeg", quality=72)["data"]'

            substituteInPlace jev_ultrafast/model.py \
              --replace-fail \
                'reasoning = {"reasoning": {"enabled": False}}' \
                'reasoning = {} if "api.groq.com/" in base else {"reasoning": {"enabled": False}}'
          '';
        });
      };

      pythonSet = pythonBase.overrideScope (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.wheel
          lockedPackages
          patches
        ]
      );

      jevPackage =
        pythonSet.mkVirtualEnv "jev-ultrafast-env" workspace.deps.default;

      startChromium = pkgs.writeShellScript "start-jev-chromium" ''
        exec ${pkgs.chromium}/bin/chromium \
          --headless=new \
          --no-first-run \
          --disable-gpu \
          --disable-dev-shm-usage \
          --remote-debugging-address=127.0.0.1 \
          --remote-debugging-port=${toString cdpPort} \
          --user-data-dir=/var/lib/jev-ultrafast/chrome \
          about:blank
      '';
    in
    {
      users.groups.jev-ultrafast = { };

      users.users.jev-ultrafast = {
        isSystemUser = true;
        group = "jev-ultrafast";
        home = "/var/lib/jev-ultrafast";
      };

      sops.secrets.openjev_key.restartUnits = [
        "jev-ultrafast.service"
      ];

      sops.secrets.groq_key.restartUnits = [
        "jev-ultrafast.service"
      ];

      sops.templates."jev-ultrafast.env" = {
        owner = "jev-ultrafast";
        group = "jev-ultrafast";
        mode = "0400";

        content = ''
          TYPESAFE_API_KEY=${config.sops.placeholder.openjev_key}
          TYPESAFE_MODEL=openjev
          TEXT_MODEL_API_KEY=${config.sops.placeholder.groq_key}
          TEXT_MODEL_BASE_URL=https://api.groq.com/openai/v1
          TEXT_MODEL=openai/gpt-oss-20b
          TEXT_MODEL_REASONING=none
          BU_CDP_URL=http://127.0.0.1:${toString cdpPort}
          BH_HOME=/var/lib/jev-ultrafast/browser-harness
          TYPESAFE_DEMO_PORT=${toString inspectorPort}
        '';

        restartUnits = [ "jev-ultrafast.service" ];
      };

      systemd.services.jev-chromium = {
        description = "Chromium for Jev Ultrafast";
        wantedBy = [ "multi-user.target" ];

        environment = {
          HOME = "/var/lib/jev-ultrafast";
          XDG_CONFIG_HOME = "/var/lib/jev-ultrafast/config";
          XDG_CACHE_HOME = "/var/lib/jev-ultrafast/cache";
        };

        serviceConfig = {
          Type = "simple";
          User = "jev-ultrafast";
          Group = "jev-ultrafast";
          StateDirectory = "jev-ultrafast";
          StateDirectoryMode = "0700";
          WorkingDirectory = "/var/lib/jev-ultrafast";
          ExecStart = startChromium;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      systemd.services.jev-ultrafast = {
        description = "Jev Ultrafast browser inspector";
        wantedBy = [ "multi-user.target" ];
        requires = [ "jev-chromium.service" ];
        after = [ "jev-chromium.service" ];

        environment = {
          HOME = "/var/lib/jev-ultrafast";
          XDG_CONFIG_HOME = "/var/lib/jev-ultrafast/config";
          XDG_CACHE_HOME = "/var/lib/jev-ultrafast/cache";
        };

        unitConfig.RequiresMountsFor = [
          config.sops.templates."jev-ultrafast.env".path
        ];

        serviceConfig = {
          Type = "simple";
          User = "jev-ultrafast";
          Group = "jev-ultrafast";
          StateDirectory = "jev-ultrafast";
          StateDirectoryMode = "0700";
          WorkingDirectory = "/var/lib/jev-ultrafast";
          EnvironmentFile = config.sops.templates."jev-ultrafast.env".path;
          ExecStart = "${jevPackage}/bin/jev";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}