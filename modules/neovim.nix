{ config, pkgs, ... }:

let
  sources = import ../nix/sources.nix;
  mini-nvim = sources."mini.nvim";
  netrw-nvim = sources."netrw.nvim";
  nvim-lspconfig = sources."nvim-lspconfig";
  guess-indent-nvim = sources."guess-indent.nvim";

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
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      pyright
      jdt-language-server
      vscode-langservers-extracted
      lemminx
    ];
    extraConfig = ''
      set mouse=nvi
      set expandtab
      let g:netrw_liststyle = 3
      let g:netrw_winsize = 30
    '';
    plugins = map mkNvimPlugin [
      {
        name = "mini.nvim";
        src = "${mini-nvim}";
        type = "lua";
        config = ''
          require("mini.ai").setup()
          require("mini.basics").setup()
          require("mini.comment").setup()
          require("mini.cursorword").setup()
          require("mini.diff").setup()
          require("mini.icons").setup()
          require("mini.git").setup()
          require("mini.pairs").setup()
          require("mini.surround").setup()
          require("mini.statusline").setup()
          require("mini.tabline").setup()
          require("mini.trailspace").setup()
        '';
      }
      {
        name = "guess-indent.nvim";
        src = "${guess-indent-nvim}";
        type = "lua";
        config = ''
          require("guess-indent").setup({})
        '';
      }
      {
        name = "nvim-lspconfig";
        src = "${nvim-lspconfig}";
        type = "lua";
        config = ''
          vim.lsp.enable('pyright')
          vim.lsp.enable('jdtls')
          vim.lsp.enable('html')
          vim.lsp.enable('cssls')
          vim.lsp.enable('jsonls')
          vim.lsp.enable('eslint')
          vim.lsp.enable('lemminx')
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
    ];
  };
}
