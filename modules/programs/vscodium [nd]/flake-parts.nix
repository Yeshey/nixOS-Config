{
  flake-file.inputs.nix-languagetool-ngram = {
    url = "github:Janik-Haag/nix-languagetool-ngram";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}