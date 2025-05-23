{ config, pkgs, ... }:

let
  sources = import ../nix/sources.nix;
  mini-nvim = sources."mini.nvim";
  netrw-nvim = sources."netrw.nvim";
  auto-dark-mode-nvim = sources."auto-dark-mode.nvim";

  # Helper function to create plugin entries
  mkNvimPlugin = { name, src, type ? "lua", config ? "" }: {
    plugin = pkgs.vimUtils.buildVimPlugin {
      inherit name src;
    };
    inherit type config;
  };
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
    '';
    plugins = map mkNvimPlugin [
      {
        name = "mini.nvim";
        src = "${mini-nvim}";
        type = "lua";
        config = ''
          require("mini.basics").setup()
          require("mini.icons").setup()
          require("mini.git").setup()
          require("mini.diff").setup()
          require("mini.surround").setup()
          require("mini.pairs").setup()
          require("mini.comment").setup()
          require("mini.ai").setup()
          require("mini.statusline").setup()
          require("mini.cursorword").setup()
          require("mini.trailspace").setup()
        '';
      }
      {
        name = "netrw.nvim";
        src = "${netrw-nvim}";
        type = "lua";
        config = ''
          require("netrw").setup({})
        '';
      }
      {
        name = "auto-dark-mode.nvim";
        src = "${auto-dark-mode-nvim}";
        type = "lua";
        config = ''
          require("auto-dark-mode").setup()
        '';
      }
    ];
  };
}