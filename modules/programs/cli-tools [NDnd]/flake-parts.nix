{ ... }:
{
  flake-file.inputs = {
    nvix.url = "github:niksingh710/nvix";
    # nixvim not needed here — nvix packages are self-contained,
    # nixvim module system only needed if you want to configure neovim declaratively yourself
  };
}