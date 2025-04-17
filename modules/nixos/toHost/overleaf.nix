{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.overleaf;
in
{
  options.toHost.overleaf = {
    enable = lib.mkEnableOption "Overleaf Service";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/docker/overleaf";
      description = "Path to store Overleaf persistent data";
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "8093";
      description = "Host port to expose Overleaf web interface";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

    # NOTHING OF THIS WORKED, you might as well wait for them to package overleaf in nixOS.

    # to make it work with docker follow: https://github.com/overleaf/overleaf/issues/881 (and you can look at https://blog.znjoa.com/2024/11/24/installing-overleaf-community-edition-on-raspberry-pi/ for more details on the commands)

    #  virtualisation.podman.enable = true;
      
    #   virtualisation.oci-containers.containers = {
    #     overleaf = {
    #       image = "abhilesh7/overleaf-arm:latest";
    #       autoStart = true;
    #       ports = [ "${cfg.port}:80" ];
    #       volumes = [ "${cfg.dataDir}:/var/lib/overleaf-data" ];
    #       extraOptions = [ "--pull=always" ];
    #     };
    #   };

    #   systemd.services.overleaf-dir-mgr = {
    #     wantedBy = [ "multi-user.target" ];
    #     script = ''
    #       if [ ! -d "${cfg.dataDir}" ]; then
    #         mkdir -p "${cfg.dataDir}"
    #         chmod 777 "${cfg.dataDir}"
    #       fi
    #     '';
    #     serviceConfig = {
    #       Type = "oneshot";
    #       User = "root";
    #     };
    #   };

    #   systemd.services.podman-overleaf = {
    #     requires = [ "overleaf-dir-mgr.service" ];
    #     after = [ "overleaf-dir-mgr.service" ];
    #   };

    #   environment.systemPackages = with pkgs; [
    #     (makeDesktopItem {
    #       name = "Overleaf";
    #       desktopName = "Overleaf";
    #       genericName = "LaTeX Editor";
    #       exec = "xdg-open http://localhost:${cfg.port}";
    #       icon = "firefox";
    #       categories = [ "Office" "X-WebApps" ];
    #     })
    #   ];
    # };

    # networking.firewall.enable = false;

    # Runtime podman
    # virtualisation.podman = {
    #   enable = true;
    #   autoPrune.enable = true;
    #   dockerCompat = lib.mkForce true;
    # };
    # virtualisation.oci-containers.backend = "podman";

    # Runtime docker
    # boot.binfmt.registrations.x86_64-linux.fixBinary = true;

    # virtualisation.docker = {
    #   enable = true;
    #   autoPrune.enable = true;
    #   extraOptions = "--add-runtime qemu-x86_64=${pkgs.qemu}/bin/qemu-x86_64-static";
    # };
    # virtualisation.oci-containers.backend = "docker";

    # # Containers
    # virtualisation.oci-containers.containers."mongo" = {
    #   image = "mongo:6.0";
    #   environment = {
    #     "MONGO_INITDB_DATABASE" = "sharelatex";
    #   };
    #   volumes = [
    #     "/home/yeshey/Downloads/overleaf/bin/shared/mongodb-init-replica-set.js:/docker-entrypoint-initdb.d/mongodb-init-replica-set.js:rw"
    #     "/home/yeshey/mongo_data:/data/db:rw"
    #   ];
    #   cmd = [ "--replSet" "overleaf" ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--add-host=mongo:127.0.0.1"
    #     "--health-cmd=echo 'db.stats().ok' | mongosh localhost:27017/test --quiet"
    #     "--health-interval=10s"
    #     "--health-retries=5"
    #     "--health-timeout=10s"
    #     "--network-alias=mongo"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-mongo" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };
    # virtualisation.oci-containers.containers."redis" = {
    #   image = "redis:6.2";
    #   volumes = [
    #     "/home/yeshey/redis_data:/data:rw"
    #   ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--network-alias=redis"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-redis" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };
    # virtualisation.oci-containers.containers."sharelatex" = {
    #   image = "sharelatex/sharelatex";
    #   # platform = "linux/amd64"; # Explicit architecture
    #   environment = {
    #     "EMAIL_CONFIRMATION_DISABLED" = "true";
    #     "ENABLED_LINKED_FILE_TYPES" = "project_file,project_output_file";
    #     "ENABLE_CONVERSIONS" = "true";
    #     "OVERLEAF_APP_NAME" = "Overleaf Community Edition";
    #     "OVERLEAF_MONGO_URL" = "mongodb://mongo/sharelatex";
    #     "OVERLEAF_REDIS_HOST" = "redis";
    #     "REDIS_HOST" = "redis";
    #     "SANDBOXED_COMPILES" = "true";
    #     "SANDBOXED_COMPILES_HOST_DIR_COMPILES" = "/home/user/sharelatex_data/data/compiles";
    #     "SANDBOXED_COMPILES_HOST_DIR_OUTPUT" = "/home/user/sharelatex_data/data/output";
    #     "SANDBOXED_COMPILES_SIBLING_CONTAINERS" = "true";
    #   };
    #   volumes = [
    #     "/home/yeshey/sharelatex_data:/var/lib/overleaf:rw"
    #   ];
    #   ports = [
    #     "8094:80/tcp"
    #   ];
    #   dependsOn = [
    #     "mongo"
    #     "redis"
    #   ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--platform=linux/amd64"
    #     "--network-alias=sharelatex"
    #     "--network=overleaf_default"
    #   ];
    # };
    # systemd.services."docker-sharelatex" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 90 "always";
    #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
    #     RestartSec = lib.mkOverride 90 "100ms";
    #     RestartSteps = lib.mkOverride 90 9;
    #   };
    #   after = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   requires = [
    #     "docker-network-overleaf_default.service"
    #   ];
    #   partOf = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    #   wantedBy = [
    #     "docker-compose-overleaf-root.target"
    #   ];
    # };

    # # Networks
    # systemd.services."docker-network-overleaf_default" = {
    #   path = [ pkgs.docker ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStop = "docker network rm -f overleaf_default";
    #   };
    #   script = ''
    #     docker network inspect overleaf_default || docker network create overleaf_default
    #   '';
    #   partOf = [ "docker-compose-overleaf-root.target" ];
    #   wantedBy = [ "docker-compose-overleaf-root.target" ];
    # };

    # # Root service
    # # When started, this will automatically create all resources and start
    # # the containers. When stopped, this will teardown all resources.
    # systemd.targets."docker-compose-overleaf-root" = {
    #   unitConfig = {
    #     Description = "Root target generated by compose2nix.";
    #   };
    #   wantedBy = [ "multi-user.target" ];
    # };

  };
}


# DEEPSEEK SUGGESTINO IF I UPLOAD MY REPOS

# { config, lib, pkgs, ... }:

# let
#   cfg = config.toHost.overleaf;
  
#   # Build the base image
#   overleaf-base = pkgs.dockerTools.buildImage {
#     name = "sharelatex/sharelatex-base";
#     tag = "main";
    
#     copyToRoot = pkgs.buildEnv {
#       name = "overleaf-base-root";
#       paths = with pkgs; [
#         bash
#         coreutils
#         gnused
#         gawk
#         findutils
#         nodejs-16_x  # Match Overleaf's Node.js version
#         python3
#         git
#         poppler_utils
#         # Add other base dependencies from Dockerfile-base
#       ];
#       pathsToLink = [ "/bin" "/lib" ];
#     };

#     runAsRoot = ''
#       #!${pkgs.runtimeShell}
#       mkdir -p /var/lib/sharelatex
#       mkdir -p /var/log/sharelatex
#       # Add other directory setup from Dockerfile-base
#     '';

#     config = {
#       WorkingDir = "/var/www/sharelatex";
#       Env = [
#         "PATH=/bin:/usr/bin:${pkgs.nodejs-16_x}/bin"
#         "NODE_ENV=production"
#       ];
#       # Include other base config from Dockerfile-base
#     };
#   };

#   # Build the community edition image
#   overleaf-community = pkgs.dockerTools.buildImage {
#     name = "sharelatex/sharelatex";
#     tag = "3.1.0";
    
#     fromImage = overleaf-base;

#     copyToRoot = let
#       overleafSrc = pkgs.fetchFromGitHub {
#         owner = "Yeshey";
#         repo = "overleaf";
#         rev = "COMMIT_HASH"; # Pin specific commit
#         sha256 = "HASH"; # Get via nix-prefetch-github
#       };
#     in pkgs.buildEnv {
#       name = "overleaf-community-root";
#       paths = [
#         (pkgs.runCommand "overleaf-app" {} ''
#           mkdir -p $out/var/www/sharelatex
#           cp -r ${overleafSrc}/server-ce/* $out/var/www/sharelatex/
#           # Apply any ARM-specific patches here
#         '')
#       ];
#     };

#     runAsRoot = ''
#       #!${pkgs.runtimeShell}
#       npm install -g forever
#       # Add any community edition specific setup
#     '';

#     config = {
#       Cmd = [ "npm" "start" ];
#       ExposedPorts = {
#         "80/tcp" = {};
#       };
#       Volumes = {
#         "/var/lib/sharelatex" = {};
#         "/var/log/sharelatex" = {};
#       };
#     };
#   };

# in {
#   # ... (keep previous options unchanged)

#   config = lib.mkIf (config.mySystem.enable && cfg.enable) {

#     virtualisation.oci-containers.containers = {
#       overleaf-mongo = { /* ... */ };
      
#       overleaf-redis = { /* ... */ };

#       overleaf-sharelatex = {
#         image = "${overleaf-community.imageName}:${overleaf-community.imageTag}";
#         dependsOn = [ "overleaf-mongo" "overleaf-redis" ];
#         ports = [ "${toString cfg.port}:80" ];
#         environment = {
#           SHARELATEX_MONGO_URL = "mongodb://overleaf-mongo:27017/sharelatex";
#           SHARELATEX_REDIS_HOST = "overleaf-redis";
#         };
#         volumes = [
#           "${cfg.dataDir}/sharelatex_data:/var/lib/sharelatex"
#           "${cfg.dataDir}/sharelatex_uploads:/var/www/sharelatex/web/uploads"
#         ];
#       };
#     };

#     systemd.services.overleaf-image-build = {
#       script = ''
#         # Ensure images are built before podman tries to use them
#         ${overleaf-community} 
#       '';
#       serviceConfig.Type = "oneshot";
#       wantedBy = [ "podman-overleaf-sharelatex.service" ];
#     };
#   };
# }

# prompt i used:

/*
so, the official overleaf docker image isn't marked with arm support. So I'm compiling the overleaf docker to have arm support and scheme-full as well.

what I had to do was clone the repositories `https://github.com/overleaf/overleaf` and `https://github.com/overleaf/toolkit`. Have them like this:
```
> tree -L 2 .
.
├── overleaf
│   ├── bin
│   ├── CONTRIBUTING.md
│   ├── develop
│   ├── doc
│   ├── docker-compose.debug.yml
│   ├── docker-compose.yml
│   ├── libraries
│   ├── LICENSE
│   ├── package.json
│   ├── package-lock.json
│   ├── patches
│   ├── README.md
│   ├── server-ce
│   ├── server-ce
│   │   ├── bin
│   │   ├── cloudbuild.public.yaml
│   │   ├── config
│   │   ├── cron
│   │   ├── Dockerfile
│   │   ├── Dockerfile-base
│   │   ├── genScript.js
│   │   ├── hotfix
│   │   ├── init_preshutdown_scripts
│   │   ├── init_scripts
│   │   ├── logrotate
│   │   ├── Makefile
│   │   ├── nginx
│   │   ├── runit
│   │   ├── services.js
│   │   └── test
│   ├── services
│   └── tsconfig.backend.json
└── toolkit
    ├── bin
    ├── CHANGELOG.md
    ├── config
    ├── data
    ├── doc
    ├── lib
    ├── LICENSE
    └── README.md
```

And then follow these instructions:
```
I managed to build the image on arm64 the way @aeaton-overleaf wrote:
1. `make build-base` and `make build-community` from `server-ce/` directory in Overleaf repository. It creates sharelatex docker images in the system.
2. `docker tag sharelatex/sharelatex:main sharelatex/sharelatex:3.1.0` (where 3.1.0 matches the version in the toolkit's `config/version` file)
3. run `bin/up` from `overleaf-toolkit` directory
And it spins up on my remote machine. (I cannot connect to it for now, but I think it's the IP problem. The image seems to work.)
```

Also:
```sh
> cat toolkit/config/version
5.4.0
```

I am in nixOS, I can push these two repositories to my github with my changes, but can I then make a nix file that builds and runs the docker correctly with those repos with nix code?

my github is `https://github.com/Yeshey/<repo-name>`. Can finish the below nix file so it can use my docker repos and build this arm overleaf docker and install it in nixOS:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.overleaf;
in
{
  options.toHost.overleaf = {
    enable = lib.mkEnableOption "Overleaf Service";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/docker/overleaf";
      description = "Path to store Overleaf persistent data";
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "8093";
      description = "Host port to expose Overleaf web interface";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {

  };
}
```

Here are the contents of the Makefile in case you need them to build the dockers with nix:
```
> cat overleaf/server-ce/Makefile
# Makefile

MONOREPO_ROOT := ../
HERE=$(shell pwd)
export MONOREPO_REVISION := $(shell git rev-parse HEAD)
export BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)
export OVERLEAF_BASE_BRANCH ?= sharelatex/sharelatex-base:$(BRANCH_NAME)
export OVERLEAF_BASE_LATEST ?= sharelatex/sharelatex-base
export OVERLEAF_BASE_TAG ?= sharelatex/sharelatex-base:$(BRANCH_NAME)-$(MONOREPO_REVISION)
export OVERLEAF_BRANCH ?= sharelatex/sharelatex:$(BRANCH_NAME)
export OVERLEAF_LATEST ?= sharelatex/sharelatex
export OVERLEAF_TAG ?= sharelatex/sharelatex:$(BRANCH_NAME)-$(MONOREPO_REVISION)

all: build-base build-community

build-base:
        cp .dockerignore $(MONOREPO_ROOT)
        docker build \
          --build-arg BUILDKIT_INLINE_CACHE=1 \
          --progress=plain \
          --file Dockerfile-base \
          --pull \
          --cache-from $(OVERLEAF_BASE_LATEST) \
          --cache-from $(OVERLEAF_BASE_BRANCH) \
          --tag $(OVERLEAF_BASE_TAG) \
          --tag $(OVERLEAF_BASE_BRANCH) \
          $(MONOREPO_ROOT)


build-community:
        cp .dockerignore $(MONOREPO_ROOT)
        docker build \
          --build-arg BUILDKIT_INLINE_CACHE=1 \
          --progress=plain \
          --build-arg OVERLEAF_BASE_TAG \
          --build-arg MONOREPO_REVISION \
          --cache-from $(OVERLEAF_LATEST) \
          --cache-from $(OVERLEAF_BRANCH) \
          --file Dockerfile \
          --tag $(OVERLEAF_TAG) \
          --tag $(OVERLEAF_BRANCH) \
          $(MONOREPO_ROOT)

SHELLCHECK_OPTS = \
        --shell=bash \
        --external-sources \
        --exclude=SC1091
SHELLCHECK_COLOR := $(if $(CI),--color=never,--color)
SHELLCHECK_FILES := { git ls-files "*.sh" -z; git grep -Plz "\A\#\!.*bash"; } | sort -zu

shellcheck:
        @$(SHELLCHECK_FILES) | xargs -0 -r docker run --rm -v $(HERE):/mnt -w /mnt \
                koalaman/shellcheck:stable $(SHELLCHECK_OPTS) $(SHELLCHECK_COLOR)

shellcheck_fix:
        @$(SHELLCHECK_FILES) | while IFS= read -r -d '' file; do \
                diff=$$(docker run --rm -v $(HERE):/mnt -w /mnt koalaman/shellcheck:stable $(SHELLCHECK_OPTS) --format=diff "$$file" 2>/dev/null); \
                if [ -n "$$diff" ] && ! echo "$$diff" | patch -p1 >/dev/null 2>&1; then echo "\033[31m$$file\033[0m"; \
                elif [ -n "$$diff" ]; then echo "$$file"; \
                else echo "\033[2m$$file\033[0m"; fi \
        done

.PHONY: all \
        build-base build-community \
        shellcheck shellcheck_fix
```

Maybe you can check how I did in the case of speedtest-tracker, but in this case it was just running a dockerimage, not builkding one from scratch:
```nix
[...]

    # journalctl -fu podman-speedtest_tracker.service
    # usually in /opt/docker (need to craeate folders manually?)
    # see here: http://localhost:8081/admin
    # default admin login: https://docs.speedtest-tracker.dev/security/authentication
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.containers = {
      speedtest_tracker = {
        image = "lscr.io/linuxserver/speedtest-tracker:0.20.6";
        volumes = [
          "/opt/docker/speedtest:/config"
          "/opt/docker/speedtest//ssl-keys:/config/keys"
        ];
        ports = [
          "${cfg.unencryptedPort}:80"
          "8443:443"
        ];
        autoStart = true;
        extraOptions = [ "--rm" "--pull=always" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          APP_KEY = "base64:tdRUioeLWq3KJup4Hr8dBwiYrb/4ICm60TbnAez61aY=";
          APP_URL = "http://localhost";
          DB_CONNECTION = "sqlite";
          SPEEDTEST_SCHEDULE = cfg.scheduele;
          AUTH = "false";
          DISPLAY_TIMEZONE = "Europe/Lisbon";
          APP_TIMEZONE = "Europe/Lisbon";
        };
        #restartPolicy = "unless-stopped";
      };
    };
    # need my own fucking service for this
    systemd.services.my-network-online = {
      wantedBy = [ "multi-user.target"];
      path = [ pkgs.iputils ];
      script = ''
        until ${pkgs.iputils}/bin/ping -c1 google.com ; do ${pkgs.coreutils}/bin/sleep 5 ; done
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
    systemd.services.podman-speedtest_tracker = {
      # This adds to the settings that were already there
      wants = [ "nss-lookup.target" "my-network-online.service"];
      after = [ "nss-lookup.target" "my-network-online.service"];
    };
    systemd.services.speedtest-tracker-mgr = {
      wantedBy = [ "multi-user.target" "podman-speedtest_tracker.service" ];
      script = ''
        WORKING_DIR="/opt/docker/speedtest"
        SSL_DIR="$WORKING_DIR/ssl-keys"

        echo "Ensuring working directory exists..."
        if [ ! -d $WORKING_DIR ]; then
          echo "Directory does not exist, creating..."
          mkdir -p $WORKING_DIR
        else
          echo "Directory already exists."
        fi

        echo "Ensuring SSL keys directory exists..."
        if [ ! -d $SSL_DIR ]; then
          echo "SSL keys directory does not exist, creating..."
          mkdir -p $SSL_DIR
        else
          echo "SSL keys directory already exists."
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
[...]
```
 */