# rclone-mount-onedrive impermanence
{
  inputs,
  ...
}:
{
  flake.modules.homeManager.rclone-mount-onedrive =
    {
      imports = [
        inputs.self.modules.homeManager.rclone-config-impermanence
      ];
    };
}