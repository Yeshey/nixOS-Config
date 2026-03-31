{ ... }:
{
  flake.modules.nixos.overleaf =
    { pkgs, lib, ... }:
    let
      dataDir = "/opt/docker/overleaf";
      port = "8093";

      overleafRepo = pkgs.fetchFromGitHub {
        owner = "Yeshey";
        repo = "overleaf";
        rev = "eebda7f63edcf095ea1a4d156b3bacb7dd23ab23";
        sha256 = "sha256-9/DNYSW+CCGCBmtkPvVl4+E2qKyECjjHX/h6og3qaB4=";
      };

      toolkitRepo = pkgs.fetchFromGitHub {
        owner = "overleaf";
        repo = "toolkit";
        rev = "895fe739417bdf4d292514036d2d65864c5d4310";
        sha256 = "sha256-G9LS4r73mGQDBbuLUsa7z4qdFJt77XZcPLe7d/bEf6Y=";
      };

      buildImagesScript = pkgs.writeShellScriptBin "build-overleaf-images" ''
        #!${pkgs.bash}/bin/bash
        set -e

        echo "Setting up Overleaf repositories and building images..."

        mkdir -p ${dataDir}/repos

        if [ ! -d "${dataDir}/repos/overleaf" ]; then
          echo "Copying Overleaf repository..."
          cp -r ${overleafRepo} ${dataDir}/repos/overleaf
          chmod -R u+w ${dataDir}/repos/overleaf
        fi

        if [ ! -d "${dataDir}/repos/toolkit" ]; then
          echo "Copying Toolkit repository..."
          cp -r ${toolkitRepo} ${dataDir}/repos/toolkit
          chmod -R u+w ${dataDir}/repos/toolkit
        fi

        export MONOREPO_REVISION="${builtins.substring 0 40 overleafRepo.rev}"
        export BRANCH_NAME="main"
        export OVERLEAF_BASE_TAG="sharelatex/sharelatex-base:$BRANCH_NAME-$MONOREPO_REVISION"
        export OVERLEAF_BASE_BRANCH="sharelatex/sharelatex-base:$BRANCH_NAME"
        export OVERLEAF_TAG="sharelatex/sharelatex:$BRANCH_NAME-$MONOREPO_REVISION"
        export OVERLEAF_BRANCH="sharelatex/sharelatex:$BRANCH_NAME"

        if [ ! -f ${dataDir}/repos/overleaf/.dockerignore ]; then
          touch ${dataDir}/repos/overleaf/.dockerignore
        fi

        if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex-base:main"; then
          echo "Building base image..."
          cp ${dataDir}/repos/overleaf/server-ce/.dockerignore ${dataDir}/repos/overleaf/ || touch ${dataDir}/repos/overleaf/.dockerignore
          ${pkgs.docker}/bin/docker build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --progress=plain \
            --file ${dataDir}/repos/overleaf/server-ce/Dockerfile-base \
            --pull \
            --tag $OVERLEAF_BASE_TAG \
            --tag $OVERLEAF_BASE_BRANCH \
            ${dataDir}/repos/overleaf
        else
          echo "Base image already exists, skipping build"
        fi

        if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex:main"; then
          echo "Building community image..."
          ${pkgs.docker}/bin/docker build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --progress=plain \
            --build-arg OVERLEAF_BASE_TAG=$OVERLEAF_BASE_TAG \
            --build-arg MONOREPO_REVISION=$MONOREPO_REVISION \
            --file ${dataDir}/repos/overleaf/server-ce/Dockerfile \
            --tag $OVERLEAF_TAG \
            --tag $OVERLEAF_BRANCH \
            ${dataDir}/repos/overleaf
        else
          echo "Community image already exists, skipping build"
        fi

        if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex:5.4.0"; then
          echo "Tagging image for toolkit..."
          ${pkgs.docker}/bin/docker tag sharelatex/sharelatex:main sharelatex/sharelatex:5.4.0
        fi

        echo "Cleaning up build artifacts..."
        ${pkgs.docker}/bin/docker image prune -f
        ${pkgs.docker}/bin/docker builder prune -f
        echo "Build cleanup completed"
      '';

      setupToolkitScript = pkgs.writeShellScriptBin "setup-overleaf-toolkit" ''
        #!${pkgs.bash}/bin/bash
        set -e

        echo "Setting up Overleaf toolkit..."

        mkdir -p ${dataDir}
        mkdir -p ${dataDir}/toolkit
        mkdir -p ${dataDir}/overleaf-data/mongo
        mkdir -p ${dataDir}/overleaf-data/redis

        if [ ! -d "${dataDir}/toolkit/bin" ]; then
          echo "Copying toolkit files..."
          cp -r ${dataDir}/repos/toolkit/* ${dataDir}/toolkit/
          chmod -R u+w ${dataDir}/toolkit
        fi

        mkdir -p ${dataDir}/toolkit/config
        cat > ${dataDir}/toolkit/config/overleaf.rc <<EOF
PROJECT_NAME=overleaf
OVERLEAF_PORT=${port}
OVERLEAF_DATA_PATH=${dataDir}/overleaf-data
OVERLEAF_LISTEN_IP=0.0.0.0

MONGO_ENABLED=true
MONGO_IMAGE=mongo
MONGO_VERSION=6.0
MONGO_DATA_PATH=${dataDir}/overleaf-data/mongo

REDIS_ENABLED=true
REDIS_DATA_PATH=${dataDir}/overleaf-data/redis
REDIS_IMAGE=redis:6.2
REDIS_AOF_PERSISTENCE=true
EOF

        cat > ${dataDir}/toolkit/config/variables.env <<EOF
OVERLEAF_APP_NAME="Overleaf"
ENABLED_LINKED_FILE_TYPES=project_file,project_output_file
ENABLE_CONVERSIONS=true
EMAIL_CONFIRMATION_DISABLED=true
SITE_URL=http://127.0.0.1:${port}
BASE_URL=http://127.0.0.1:${port}
RESTRICT_INVITES_TO_EXISTING_ACCOUNTS=false
EOF

        echo "5.4.0" > ${dataDir}/toolkit/config/version

        chmod +x ${dataDir}/toolkit/bin/up
        chmod +x ${dataDir}/toolkit/bin/docker-compose

        echo "Toolkit setup completed successfully"
      '';

      startOverleafScript = pkgs.writeShellScriptBin "start-overleaf" ''
        #!${pkgs.bash}/bin/bash
        set -e

        cd ${dataDir}/toolkit

        if ${pkgs.docker}/bin/docker ps -a | grep -q "sharelatex"; then
          echo "Stopping existing Overleaf containers..."
          ./bin/docker-compose down || true
        fi

        echo "Starting Overleaf..."
        exec ./bin/up
      '';

      requiredPkgs = with pkgs; [
        bash coreutils docker docker-compose git gnugrep gnutar gzip
        gnused findutils gawk nettools procps which gnumake hostname
      ];

    in
    {
      virtualisation.docker.enable = true;

      systemd.services.overleaf-dir-setup = {
        description = "Setup Overleaf directories";
        wantedBy = [ "multi-user.target" ];
        before = [ "overleaf-build.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
        };
        script = ''
          mkdir -p ${dataDir}/repos
          mkdir -p ${dataDir}/overleaf-data/mongo
          mkdir -p ${dataDir}/overleaf-data/redis
        '';
      };

      systemd.services.overleaf-build = {
        description = "Build Overleaf Docker images";
        requires = [ "docker.service" "overleaf-dir-setup.service" ];
        after = [ "docker.service" "overleaf-dir-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        before = [ "overleaf-setup.service" ];
        path = requiredPkgs;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
          TimeoutStartSec = "120min";
        };
        script = "${buildImagesScript}/bin/build-overleaf-images";
      };

      systemd.services.overleaf-setup = {
        description = "Setup Overleaf toolkit";
        requires = [ "overleaf-build.service" ];
        after = [ "overleaf-build.service" ];
        wantedBy = [ "multi-user.target" ];
        before = [ "overleaf.service" ];
        path = requiredPkgs;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "root";
        };
        script = "${setupToolkitScript}/bin/setup-overleaf-toolkit";
      };

      systemd.services.overleaf = {
        description = "Overleaf Service";
        requires = [ "docker.service" "overleaf-setup.service" ];
        after = [ "docker.service" "overleaf-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        path = requiredPkgs;
        serviceConfig = {
          Type = "simple";
          User = "root";
          Restart = "on-failure";
          RestartSec = "10s";
          WorkingDirectory = "${dataDir}/toolkit";
          ExecStart = "${startOverleafScript}/bin/start-overleaf";
        };
        preStop = ''
          cd ${dataDir}/toolkit
          ./bin/docker-compose down || true
        '';
      };

      environment.systemPackages = [
        buildImagesScript
        setupToolkitScript
        startOverleafScript
        pkgs.docker-compose
      ] ++ requiredPkgs;

      networking.firewall.allowedTCPPorts = [ (lib.toInt port) ];

      environment.etc."overleaf/REVISION".text = overleafRepo.rev;
    };
}