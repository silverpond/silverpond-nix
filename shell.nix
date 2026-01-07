{ cuda ? false }:

let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
      cudaSupport = cuda;
    };
  };
  pythonOverrides = import ./python-overrides.nix { inherit pkgs; };
  python = pkgs.python3.override {
    packageOverrides = pythonOverrides;
    self = python;
  };
in
pkgs.mkShell {
  packages = [
    (python.withPackages (ps: [ ps.torch ps.highlighter-sdk ]))
  ];
}
