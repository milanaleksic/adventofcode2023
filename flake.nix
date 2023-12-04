{
  description = "ThoughtTrain";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    nixpkgs-unstable.url = github:NixOS/nixpkgs;
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
        devShell =
          with nixpkgs.legacyPackages.${system};
          mkShell {
            buildInputs = [
              nixpkgs-unstable.legacyPackages.${system}.zig
              nixpkgs-unstable.legacyPackages.${system}.zls
              nixpkgs-unstable.legacyPackages.${system}.lldb
            ];
            shellHook = ''
              '';
          };
      }
  );
}

