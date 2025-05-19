let

  sources = import ./nix/sources.nix;

  nixpkgsUnstable = sources."nixpkgs-unstable";
  nixpkgsStable = sources."nixpkgs-stable";
  nixGL = sources."nixGL";
  home-manager = sources."home-manager";
  netrw-nvim = sources."netrw.nvim";
  nvim-web-devicons = sources."nvim-web-devicons";

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
      home-manager=${home-manager}:
      netrw-nvim=${netrw-nvim}:
      nvim-web-devicons=${nvim-web-devicons}"
    export HOME_MANAGER_CONFIG="./home.nix"
  '';

}
