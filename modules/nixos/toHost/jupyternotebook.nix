{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toHost.jupyter;
  morePackages = [
    # Needed for git interface
    pkgs.git
    pkgs.openssh

    pkgs.direnv
    pkgs.nix-direnv
  ];
  myPythonPkgs = with pkgs.python3.pkgs; [
    jupyter
    jupyterlab
    jupyter-collaboration
    jupyterlab-git
    jupyterlab-lsp  # Language Server Protocol support (syntax highlighting, autocomplete)
    python-lsp-server  # Python LSP backend
    jupyterlab-widgets  # Interactive widgets
    ipykernel

    tensorflow
    torch
    keras
    pandas
    numpy
    matplotlib
    nltk
    spacy
    progressbar
    transformers
    datasets
    graphviz
  ];
in
{
  options.toHost.jupyter = {
    enable = (lib.mkEnableOption "jupyter notebook");
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Port number for Jupyter notebook server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.jupyter = {
        enable = true;
        port = cfg.port;
        ip = "0.0.0.0"; # Listen on all interfaces for remote access
        
        # Use JupyterLab with the collaborative flag
        command = "jupyter lab --collaborative";

        package = pkgs.python3.pkgs.jupyterlab;
        
        # Password hash
        password = "argon2:$argon2id$v=19$m=10240,t=10,p=8$57N4ZfchGTheSkqeHXxoRQ$OQruwBlNX6eB+69pm/5VmnTR0wdGaoWMSbufbq9DCaY";
        
        # Add all other packages here
        extraPackages = with pkgs.python3.pkgs; [

        ] ++ myPythonPkgs;
        
        # Enable collaboration-friendly settings
        notebookConfig = ''
          # Remote access settings
          c.ServerApp.allow_remote_access = True
          c.ServerApp.allow_origin = '*'
          c.ServerApp.open_browser = False
          
          # Show hidden files and folders
          c.ContentsManager.allow_hidden = True
          
          # Collaboration settings
          c.LabApp.collaborative = True
        '';

        kernels = {
          python3 = let
            env = (pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
                  ] ++ myPythonPkgs ));
          in {
            displayName = "Baseline Python 3 for ML (creating .venv preferable)";
            argv = [
              "${env.interpreter}"
              "-m"
              "ipykernel_launcher"
              "-f"
              "{connection_file}"
            ];
            language = "python";
            extraPaths = {
              "cool.txt" = pkgs.writeText "cool" "cool content";
            };
          };
        };
      };

      systemd.services.jupyter = {
        path = [ ] ++ morePackages;
        serviceConfig = {
          StateDirectory = "jupyter";
          StateDirectoryMode = "0755";
        };
      };
      networking.firewall.allowedTCPPorts = [ cfg.port ];
      
      environment.systemPackages = [ ] ++ morePackages;
    })

    # Persist Jupyter runtime and configuration data
    (lib.mkIf (cfg.enable && config.mySystem.impermanence.enable) {
      environment.persistence."/persistent" = {
        directories = [
          { directory = "/var/lib/jupyter"; user = "jupyter"; group = "jupyter"; mode = "u=rwx,g=rx,o=";
          }
        ];
      };
    })
  ];
}