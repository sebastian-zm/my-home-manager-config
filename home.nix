{ config, pkgs, lib, ... }:
let
  nixos-artwork = pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixos-artwork";
    rev = "de03e887f03037e7e781a678b57fdae603c9ca20";
    hash = "sha256-78FyNyGtDZogJUWcCT6A/T2MK87nGN/muC7ANH1b1V8=";
  };
in {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
    "steamcmd"
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "sebastian";
  home.homeDirectory = "/home/sebastian";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.cascadia-code
    pkgs.xfce.thunar
    pkgs.wl-clipboard
    pkgs.steam
    pkgs.steam-tui
    pkgs.proton-pass
    pkgs.unzip
    pkgs.simple-http-server
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/sebastian/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Sebastian";
    userEmail = "sebastian@example.invalid";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      vim-vinegar
      vim-unimpaired
      vim-surround
      vim-sleuth
      vim-sensible
      vim-repeat
      vim-rails
      vim-ragtag
      vim-pandoc-syntax
      vim-pandoc
      vim-fugitive
      vim-eunuch
      vim-endwise
      vim-abolish
      fzf-vim
      editorconfig-vim
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.librewolf.enable = true;
  programs.librewolf.settings = {
    "privacy.resistFingerprinting.letterboxing" = true;
    "browser.safebrowsing.malware.enabled" = true;
    "browser.safebrowsing.phishing.enabled" = true;
    "browser.safebrowsing.blockedURIs.enabled" = true;
    "browser.safebrowsing.downloads.enabled" = true;
    "browser.safebrowsing.provider.google4.gethashURL" = "https://safebrowsing.googleapis.com/v4/fullHashes:find?$ct=application/x-protobuf&key=%GOOGLE_SAFEBROWSING_API_KEY%&$httpMethod=POST";
    "browser.safebrowsing.provider.google4.updateURL" = "https://safebrowsing.googleapis.com/v4/threatListUpdates:fetch?$ct=application/x-protobuf&key=%GOOGLE_SAFEBROWSING_API_KEY%&$httpMethod=POST";
    "browser.safebrowsing.provider.google.gethashURL" = "https://safebrowsing.google.com/safebrowsing/gethash?client=SAFEBROWSING_ID&appver=%MAJOR_VERSION%&pver=2.2";
    "browser.safebrowsing.provider.google.updateURL" = "https://safebrowsing.google.com/safebrowsing/downloads?client=SAFEBROWSING_ID&appver=%MAJOR_VERSION%&pver=2.2&key=%GOOGLE_SAFEBROWSING_API_KEY%";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font.normal.family = "Cascadia Code";
      font.bold = {
        family = "Cascadia Code";
        style = "bold";
      };
      font.italic = {
        family = "Cascadia Code";
        style = "italic";
      };
    };
  };

  services.mako.enable = true;
  services.kanshi.enable = true;

  wayland.windowManager.sway = {
    enable = true;
    # checkConfig = false;
    wrapperFeatures.gtk = true;
    config = rec {
      terminal = "alacritty";
      modifier = "Mod4";
      defaultWorkspace = "workspace number 1";
      input."type:keyboard" = {
        xkb_layout = "es";
        # xkb_variant = "altgr-intl";
      };
      input."type:touchpad" = {
        tap = "enabled";
      };
      output."*" = {
        bg = "${nixos-artwork}/wallpapers/nixos-wallpaper-catppuccin-frappe.png fill";
      };
      fonts = {
        names = [ "Cascadia Code" ];
        size = 10.0;
      };
      keybindings = lib.mkOptionDefault {
        "${modifier}+Shift+Return" = "exec ${pkgs.librewolf}/bin/librewolf";
      };
    };
  };

  fonts.fontconfig.enable = true;
}
