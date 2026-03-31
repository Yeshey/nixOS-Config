{ ... }:
{
  flake.modules.nixos.jupyter =
    { pkgs, ... }:
    let
      port = 8888;
      morePackages = [
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
        jupyterlab-lsp
        python-lsp-server
        jupyterlab-widgets
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
      services.jupyter = {
        enable = true;
        port = port;
        ip = "0.0.0.0";
        command = "jupyter lab --collaborative";
        package = pkgs.python3.pkgs.jupyterlab;
        # Password hash (argon2)
        password = "argon2:$argon2id$v=19$m=10240,t=10,p=8$57N4ZfchGTheSkqeHXxoRQ$OQruwBlNX6eB+69pm/5VmnTR0wdGaoWMSbufbq9DCaY";
        extraPackages = myPythonPkgs;
        notebookConfig = ''
          c.ServerApp.allow_remote_access = True
          c.ServerApp.allow_origin = '*'
          c.ServerApp.open_browser = False
          c.ContentsManager.allow_hidden = True
          c.LabApp.collaborative = True
        '';
        kernels.python3 =
          let
            env = pkgs.python3.withPackages (_: myPythonPkgs);
          in
          {
            displayName = "Baseline Python 3 for ML (creating .venv preferable)";
            argv = [ "${env.interpreter}" "-m" "ipykernel_launcher" "-f" "{connection_file}" ];
            language = "python";
            extraPaths."cool.txt" = pkgs.writeText "cool" "cool content";
          };
      };

      systemd.services.jupyter = {
        path = morePackages;
        serviceConfig = {
          StateDirectory = "jupyter";
          StateDirectoryMode = "0755";
        };
      };

      networking.firewall.allowedTCPPorts = [ port ];
      environment.systemPackages = morePackages;
    };
}