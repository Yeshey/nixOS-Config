{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.templates;
in
{
  config = { # always active

    home.file."Templates/Markdown.md".text = "";
    home.file."Templates/Text.txt".text = "";

  };
}
