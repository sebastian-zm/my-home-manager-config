{ config, pkgs, ... }:

let
  stablepkgs = import <nixpkgs-stable> { config.allowUnfree = true; };
  nixgl = import <nixGL> {};
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
    packages = nixgl;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with stablepkgs; [
    # (pkgs.writeShellScriptBin "vim-plugin" ''
    #   find $HOME/.vim/pack/*/start/ -maxdepth 1 -mindepth 1 -type d | ${pkgs.parallel}/bin/parallel git -C {} pull
    #   ${pkgs.vim}/bin/vim -u NONE -c "helptags ALL" -c q
    # '')
    (writeShellScriptBin "llm" ''
      ${pkgs.ollama}/bin/ollama run qwen3:30b
    '')
    (writeShellScriptBin "git-to-llm" ''
      GIT=${pkgs.git}/bin/git
      # Ensure we're in a git repository
      if ! git rev-parse --is-inside-work-tree &>/dev/null; then
          echo "Error: Not in a git repository."
          exit 1
      fi

      # Retrieve the list of files (tracked, untracked, and not ignored)
      git ls-files --cached --others --exclude-standard | while read -r file; do
          echo 'file path: `'"$file"'`'
          echo 'file contents: '

          echo '```'
          cat "$file"
          echo '```'
      done
    '')
    # Uses system podman
    (writeShellScriptBin "docker" ''
      PODMAN_COMPOSE_PROVIDER=${docker-compose}/bin/docker-compose DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock PODMAN_USERNS=keep-id:uid=1000,gid=1000 exec podman "$@"
    '')

    docker-compose
    tcpdump
    wl-clipboard
    parallel
    libtree
    jq
    uv
    nodenv
    websocat
    pkgs.cloudflared
    simple-http-server
    nmap
    bat
    btop
    dust
    pkgs.ollama
    imagemagick
  ] ++ (map config.lib.nixGL.wrap [
    ciscoPacketTracer8
    pinta
    minder
    pkgs.whatsie
    flowblade
    wpsoffice
    libreoffice
    pkgs.signal-desktop
    prismlauncher
    inkscape-with-extensions
    krita
    pkgs.azahar
    kdePackages.kcalc
    kdePackages.kalgebra
    kdePackages.skanpage
    kdePackages.kamera
  ]);

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

  programs.freetube = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.freetube; 
  };

  programs.vscode = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-vscode-remote.remote-containers
    ];
  };

  programs.neovim = {
    enable = true;
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
      vim-ragtag
      vim-fugitive
      vim-eunuch
      vim-endwise
      vim-abolish
      fzf-vim
    ];
  };

  programs.fzf = {
    enable = true;
    package = stablepkgs.fzf;
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

  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  # programs.home-manager = {
  #   enable = true;
  # };

  # services.home-manager.autoExpire = {
  #   enable = true;
  #   frequency = "weekly";
  #   store.cleanup = true;
  # };

  systemd.user = {
    services = {
      
      simple-http-server = {
        Unit = {
          Description = "An http server to share files";
          Wants = [ "var-home-sebastian-Public.mount" ];
          After = [ "var-home-sebastian-Public.mount" ];
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
          RestartSec = 59;
          Environment = "PATH=$PATH";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
