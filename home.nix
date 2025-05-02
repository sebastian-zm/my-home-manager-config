{ config, pkgs, ... }:

let
  stablepkgs = import <nixos-stable> { config.allowUnfree = true; };
  nixgl = import <nixgl> {};
  # exo = pkgs.exo.overrideAttrs (
  #   attrs: {
  #     propagatedBuildInputs = attrs.propagatedBuildInputs or [] ++ [
  #       pkgs.python312Packages.torch
  #       pkgs.python312Packages.flax
  #       pkgs.python312Packages.tensorflow
  #       pkgs.python312Packages.llvmlite
  #     ];
  #   }
  # );
  
  # ciscoPacketTracer8 = pkgs.ciscoPacketTracer8.overrideAttrs (
  #   attrs: {
  #     propagatedBuildInputs = attrs.propagatedBuildInputs or [] ++ [
  #       pkgs.kdePackages.qtwebengine
  #     ];
  #     nativeBuildInputs = attrs.nativeBuildInputs or [] ++ [
  #       pkgs.kdePackages.wrapQtAppsHook
  #     ];
  #   }
  # );
  # ktechlab = config.lib.nixGL.wrap (pkgs.stdenv.mkDerivation rec {
  #   pname = "ktechlab";
  #   version = "0.50.0";
  #   src = pkgs.fetchgit {
  #     url = "https://invent.kde.org/sdk/ktechlab.git";
  #     rev = "v${version}";
  #     hash = "sha256-de+MJZqDKToarHzfTg5/f/3f7A5EKAx+bKgU/pljNZg=";
  #   };
  #   buildInputs = with pkgs; [
  #     qt5.qtbase
  #     plasma5Packages.kdeFrameworks.plasma-framework
  #     plasma5Packages.kdeFrameworks.khtml
  #     plasma5Packages.kdeFrameworks.kparts
  #     plasma5Packages.kdeFrameworks.ktexteditor
  #   ];
  #   nativeBuildInputs = with pkgs; [
  #     cmake
  #     extra-cmake-modules
  #     qt5.wrapQtAppsHook
  #   ];
  # });
in
{
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

  nixGL = {
    packages = import <nixgl> {};
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "vim-plugin" ''
    #   find $HOME/.vim/pack/*/start/ -maxdepth 1 -mindepth 1 -type d | ${pkgs.parallel}/bin/parallel git -C {} pull
    #   ${pkgs.vim}/bin/vim -u NONE -c "helptags ALL" -c q
    # '')
    (pkgs.writeShellScriptBin "llm" ''
      ${pkgs.ollama}/bin/ollama run gemma3
    '')
    # Uses system podman
    (pkgs.writeShellScriptBin "docker" ''
      PODMAN_USERNS=keep-id
      exec podman "$@"
    '')

    pkgs.exo
    pkgs.tcpdump
    pkgs.parallel
    pkgs.libtree
    pkgs.jq
    pkgs.websocat
    pkgs.ntfy-sh
    pkgs.simple-http-server
    pkgs.nmap
    pkgs.bat
    pkgs.btop
    pkgs.dust
    pkgs.fzf
    pkgs.ollama
    pkgs.imagemagick
    (config.lib.nixGL.wrap stablepkgs.ciscoPacketTracer8)
  ];

  programs.librewolf = {
    enable = true;
    settings = {
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
  };

  programs.vscode = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-vscode-remote.remote-containers
      asvetliakov.vscode-neovim
    ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
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
    enableBashIntegration = true;
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
    # EDITOR = "vi";
  };

  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };

  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
    store.cleanup = true;
  };

  systemd.user = {
    services = {
      
      # exo = {
      #   Unit = {
      #     Description = "Run your own AI cluster at home with everyday devices.";
      #   };
      #   Install = {
      #     WantedBy = [ "default.target" ];
      #   };
      #   Service = {
      #     ExecStart = "${exo}/bin/exo --disable-tui";
      #   };
      # };

      simple-http-server = {
        Unit = {
          Description = "An http server to share files";
          Wants = [ "var-home-sebastian-Public.mount" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server --upload --port 4080";
          WorkingDirectory = "/home/sebastian/Public/";
        };
      };

      ollama = {
        Unit = {
          Description = "Ollama service";
          After = "network-online.target";
        };
        Service = {
          ExecStart = "${pkgs.ollama}/bin/ollama serve";
          Restart = "always";
          RestartSec = 10;
          Environment = "PATH=$PATH";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
