{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.myHome.homeApps.devops;
in
{
  options.myHome.homeApps.devops.enable = lib.mkEnableOption "devops";
  config = lib.mkIf (config.myHome.enable && config.myHome.homeApps.enable && cfg.enable) {
    programs.zsh.shellAliases = {
      tf = "terraform";
    };
    home.packages = with pkgs; [
      act
      ansible
      awscli2
      azure-cli
      eksctl
      fluxcd
      kind
      kubectl
      kubelogin
      kubelogin-oidc
      kubernetes-helm
      kubeseal
      minio-client
      mysql-client
      openstackclient
      packer
      swiftclient
      terraform
      tilt
      unstable.kubernetes-polaris
      unstable.kubeshark
      unstable.k3d
      unstable.k9s
      unstable.teleport.client
      (writeShellApplication {
        name = "kctx";
        runtimeInputs = [
          kubectl
          fzf
        ];
        text = ''
          kubectl config get-contexts -o name \
          | fzf --height=10 \
          | xargs kubectl config use-context
        '';
      })
      (writeShellApplication {
        name = "kctn";
        runtimeInputs = [
          kubectl
          fzf
        ];
        text = ''
          kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
            | fzf --height=10 \
            | xargs kubectl config set-context --current --namespace
        '';
      })
    ];
  };
}
