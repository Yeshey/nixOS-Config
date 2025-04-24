{
  config,
  lib,
  pkgs,
  ...
}:

# Made with help by claude
let
  cfg = config.toHost.overleaf;
  
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

  # Script to copy repos, build images, and prepare environment
  buildImagesScript = pkgs.writeShellScriptBin "build-overleaf-images" ''
    #!${pkgs.bash}/bin/bash
    set -e
    
    echo "Setting up Overleaf repositories and building images..."
    
    # Create directories
    mkdir -p ${cfg.dataDir}/repos
    
    # Copy repositories if not already present
    if [ ! -d "${cfg.dataDir}/repos/overleaf" ]; then
      echo "Copying Overleaf repository..."
      cp -r ${overleafRepo} ${cfg.dataDir}/repos/overleaf
      chmod -R u+w ${cfg.dataDir}/repos/overleaf
    fi
    
    if [ ! -d "${cfg.dataDir}/repos/toolkit" ]; then
      echo "Copying Toolkit repository..."
      cp -r ${toolkitRepo} ${cfg.dataDir}/repos/toolkit
      chmod -R u+w ${cfg.dataDir}/repos/toolkit
    fi
    
    # Set up build environment
    export MONOREPO_REVISION="${builtins.substring 0 40 overleafRepo.rev}"
    export BRANCH_NAME="main"
    export OVERLEAF_BASE_BRANCH="sharelatex/sharelatex-base:$BRANCH_NAME"
    export OVERLEAF_BASE_LATEST="sharelatex/sharelatex-base"
    export OVERLEAF_BASE_TAG="sharelatex/sharelatex-base:$BRANCH_NAME-$MONOREPO_REVISION"
    export OVERLEAF_BRANCH="sharelatex/sharelatex:$BRANCH_NAME"
    export OVERLEAF_LATEST="sharelatex/sharelatex"
    export OVERLEAF_TAG="sharelatex/sharelatex:$BRANCH_NAME-$MONOREPO_REVISION"
    
    # Ensure .dockerignore exists
    if [ ! -f ${cfg.dataDir}/repos/overleaf/.dockerignore ]; then
      touch ${cfg.dataDir}/repos/overleaf/.dockerignore
    fi
    
    # Build base image if it doesn't exist
    if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex-base:main"; then
      echo "Building base image..."
      cp ${cfg.dataDir}/repos/overleaf/server-ce/.dockerignore ${cfg.dataDir}/repos/overleaf/ || touch ${cfg.dataDir}/repos/overleaf/.dockerignore
      ${pkgs.docker}/bin/docker build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --progress=plain \
        --file ${cfg.dataDir}/repos/overleaf/server-ce/Dockerfile-base \
        --pull \
        --tag $OVERLEAF_BASE_TAG \
        --tag $OVERLEAF_BASE_BRANCH \
        ${cfg.dataDir}/repos/overleaf
    else
      echo "Base image already exists, skipping build"
    fi
    
    # Build community image if it doesn't exist
    if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex:main"; then
      echo "Building community image..."
      ${pkgs.docker}/bin/docker build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --progress=plain \
        --build-arg OVERLEAF_BASE_TAG=$OVERLEAF_BASE_TAG \
        --build-arg MONOREPO_REVISION=$MONOREPO_REVISION \
        --file ${cfg.dataDir}/repos/overleaf/server-ce/Dockerfile \
        --tag $OVERLEAF_TAG \
        --tag $OVERLEAF_BRANCH \
        ${cfg.dataDir}/repos/overleaf
    else
      echo "Community image already exists, skipping build"
    fi
    
    # Tag for toolkit
    if ! ${pkgs.docker}/bin/docker images | grep -q "sharelatex/sharelatex:5.4.0"; then
      echo "Tagging image for toolkit..."
      ${pkgs.docker}/bin/docker tag sharelatex/sharelatex:main sharelatex/sharelatex:5.4.0
    fi
    
    echo "Docker images built successfully"
  '';

  # Setup toolkit config script
  setupToolkitScript = pkgs.writeShellScriptBin "setup-overleaf-toolkit" ''
    #!${pkgs.bash}/bin/bash
    set -e
    
    echo "Setting up Overleaf toolkit..."
    
    # Create directories
    mkdir -p ${cfg.dataDir}
    mkdir -p ${cfg.dataDir}/toolkit
    mkdir -p ${cfg.dataDir}/overleaf-data
    mkdir -p ${cfg.dataDir}/overleaf-data/mongo
    mkdir -p ${cfg.dataDir}/overleaf-data/redis
    
    # Copy toolkit files if not already present
    if [ ! -d "${cfg.dataDir}/toolkit/bin" ]; then
      echo "Copying toolkit files..."
      cp -r ${cfg.dataDir}/repos/toolkit/* ${cfg.dataDir}/toolkit/
      chmod -R u+w ${cfg.dataDir}/toolkit
    fi
    
    # Ensure toolkit config file exists
    mkdir -p ${cfg.dataDir}/toolkit/config
    cat > ${cfg.dataDir}/toolkit/config/overleaf.rc <<EOF
# Main Overleaf configuration
PROJECT_NAME=overleaf
OVERLEAF_PORT=${cfg.port}
OVERLEAF_DATA_PATH=${cfg.dataDir}/overleaf-data
OVERLEAF_LISTEN_IP=0.0.0.0

# MongoDB configuration 
MONGO_ENABLED=true
MONGO_IMAGE=mongo
MONGO_VERSION=6.0
MONGO_DATA_PATH=${cfg.dataDir}/overleaf-data/mongo

# Redis configuration
REDIS_ENABLED=true
REDIS_DATA_PATH=${cfg.dataDir}/overleaf-data/redis
REDIS_IMAGE=redis:6.2
REDIS_AOF_PERSISTENCE=true
EOF

    # Create variables.env file
    cat > ${cfg.dataDir}/toolkit/config/variables.env <<EOF
#### variables.env ####
OVERLEAF_APP_NAME="Overleaf"

ENABLED_LINKED_FILE_TYPES=project_file,project_output_file

# Enables Thumbnail generation using ImageMagick
ENABLE_CONVERSIONS=true

# Disables email confirmation requirement
EMAIL_CONFIRMATION_DISABLED=true

# Allow accessing via IP address
SITE_URL=http://127.0.0.1:${cfg.port}
BASE_URL=http://127.0.0.1:${cfg.port}
# Disable strict host matching if needed
RESTRICT_INVITES_TO_EXISTING_ACCOUNTS=false

EOF

    # Ensure version file exists
    echo "5.4.0" > ${cfg.dataDir}/toolkit/config/version
    
    # Make toolkit scripts executable
    chmod +x ${cfg.dataDir}/toolkit/bin/up
    chmod +x ${cfg.dataDir}/toolkit/bin/docker-compose
    
    echo "Toolkit setup completed successfully"
  '';

  # Script to start Overleaf service
  startOverleafScript = pkgs.writeShellScriptBin "start-overleaf" ''
    #!${pkgs.bash}/bin/bash
    set -e
    
    cd ${cfg.dataDir}/toolkit
    
    # Check if there are existing containers that need to be stopped
    if ${pkgs.docker}/bin/docker ps -a | grep -q "sharelatex"; then
      echo "Stopping existing Overleaf containers..."
      ./bin/docker-compose down || true
    fi
    
    # Start Overleaf using toolkit
    echo "Starting Overleaf..."
    exec ./bin/up
  '';

  # Required packages for scripts
  requiredPkgs = with pkgs; [
    bash
    coreutils
    docker
    docker-compose
    git
    gnugrep
    gnutar
    gzip
    gnused
    findutils
    gawk
    nettools
    procps
    which
    gnumake
    hostname
  ];

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
    forceBuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force rebuilding Docker images even if they exist";
    };
  };

  config = lib.mkIf (config.mySystem.enable && cfg.enable) {
    # Enable Docker
    virtualisation.docker.enable = true;
    
    # Directory setup service
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
        #!${pkgs.bash}/bin/bash
        mkdir -p ${cfg.dataDir}
        mkdir -p ${cfg.dataDir}/repos
        mkdir -p ${cfg.dataDir}/overleaf-data
        mkdir -p ${cfg.dataDir}/overleaf-data/mongo
        mkdir -p ${cfg.dataDir}/overleaf-data/redis
      '';
    };

    # Build Docker images
    systemd.services.overleaf-build = {
      description = "Build Overleaf Docker images";
      requires = [ "docker.service" "overleaf-dir-setup.service" ];
      after = [ "docker.service" "overleaf-dir-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      before = [ "overleaf-setup.service" ];
      path = requiredPkgs;
      environment = lib.optionalAttrs cfg.forceBuild {
        FORCE_BUILD = "true";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        TimeoutStartSec = "120min"; # Building might take a long time
      };
      script = "${buildImagesScript}/bin/build-overleaf-images";
    };

    # Setup Overleaf toolkit
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

    # Run Overleaf service
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
        WorkingDirectory = "${cfg.dataDir}/toolkit";
        ExecStart = "${startOverleafScript}/bin/start-overleaf";
      };
      preStop = ''
        #!${pkgs.bash}/bin/bash
        cd ${cfg.dataDir}/toolkit
        ./bin/docker-compose down || true
      '';
    };

    # Add tools to the system environment
    environment.systemPackages = [ 
      buildImagesScript
      setupToolkitScript
      startOverleafScript
      pkgs.docker-compose
    ] ++ requiredPkgs;

    # Firewall configuration
    networking.firewall.allowedTCPPorts = [ (lib.toInt cfg.port) ];
    
    # Create a directory in /etc for overleaf specific configs
    environment.etc."overleaf/REVISION".text = overleafRepo.rev;
  };
}
# prompt i used:

/*
so, the official overleaf docker image isn't marked with arm support. So I'm compiling the overleaf docker to have arm support and scheme-full latex as well.

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
2. `docker tag sharelatex/sharelatex:main sharelatex/sharelatex:5.4.0` (where 5.4.0 matches the version in the toolkit's `config/version` file)
3. run `bin/up` from `overleaf-toolkit` directory
And it spins up on my remote machine. (I cannot connect to it for now, but I think it's the IP problem. The image seems to work.)
```

Also:
```sh
> cat toolkit/config/version
5.4.0
```

I am in nixOS, I pushed the overleaf repo fork that I used to build the overleaf docker images with latex-full to `https://github.com/Yeshey/overleaf`. And the toolkit overleaf repo I used was this one in this commit with no changes so I didn't fork it: `https://github.com/overleaf/toolkit/tree/895fe739417bdf4d292514036d2d65864c5d4310`
I now need a nix file that builds and runs the docker correctly with those repos with nix code to put in my nixOS configuration
YOu can use this to pull the repositories:
```nix
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
```

Can finish the below nix file so it can use my docker repos and build this arm overleaf docker and install it in nixOS:

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