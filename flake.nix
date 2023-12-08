{
  description = "AOC2023";
  inputs = {
    # 0.11.0 is on revision e1ee359d16a1886f0771cc433a00827da98d861c
    # look at: https://lazamar.co.uk/nix-versions/?package=zig&version=0.11.0&fullName=zig-0.11.0&keyName=zig&revision=e1ee359d16a1886f0771cc433a00827da98d861c&channel=nixos-unstable#instructions
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/e1ee359d16a1886f0771cc433a00827da98d861c";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs-pinned, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
        devShell =
          with nixpkgs-pinned.legacyPackages.${system};
          mkShell {
            buildInputs = [
              nixpkgs-pinned.legacyPackages.${system}.zig
              nixpkgs-pinned.legacyPackages.${system}.zls
              nixpkgs-pinned.legacyPackages.${system}.lldb
            ];
            shellHook = ''
              '';
          };
      }
  );
}
