let

  sources = import ./nix/sources.nix;

  nixpkgsUnstable = sources."nixpkgs-unstable";
  nixpkgsStable = sources."nixpkgs-stable";
  nixGL = sources."nixGL";
  home-manager = sources."home-manager";

  pkgs = import nixpkgsUnstable { };
  homeMgr = import home-manager { inherit pkgs; };

in pkgs.mkShell rec {

  name = "home-manager-shell";

  buildInputs = with pkgs; [
    niv
    homeMgr.home-manager
  ];

  shellHook = ''
    export NIX_PATH="
      nixpkgs=${nixpkgsUnstable}:
      nixpkgs-stable=${nixpkgsStable}:
      nixGL=${nixGL}:
      home-manager=${home-manager}"
    export HOME_MANAGER_CONFIG="./home.nix"
  '';

}
