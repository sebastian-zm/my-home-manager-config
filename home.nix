{ config, pkgs, ... }:

let
  stablepkgs = import <nixpkgs-stable> { config.allowUnfree = true; };
  nixgl = import <nixGL> {};
in
{
  imports = [
    ./modules/neovim.nix
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

  nixGL = {
    packages = nixgl;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with stablepkgs; [
    (writeShellScriptBin "llm" ''
      ${pkgs.ollama}/bin/ollama run qwen3:30b
    '')
    (writeShellScriptBin "git-to-llm" ''
      GIT=${git}/bin/git
      # Ensure we're in a git repository
      if ! $GIT rev-parse --is-inside-work-tree &>/dev/null; then
          echo "Error: Not in a git repository."
          exit 1
      fi

      # Retrieve the list of files (tracked, untracked, and not ignored)
      $GIT ls-files --cached --others --exclude-standard | while read -r file; do
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
    (writeShellScriptBin "dvc" ''
      DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock ${pkgs.devcontainer}/bin/devcontainer "$@"
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
    pkgs.devcontainer
    pkgs.cloudflared
    simple-http-server
    nmap
    btop
    aider-chat
    dust
    pkgs.ollama
    imagemagick
  ] ++ (map config.lib.nixGL.wrap [
    pkgs.ciscoPacketTracer8
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

  programs.freetube = {
    enable = true;
    package = config.lib.nixGL.wrap stablepkgs.freetube;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hidden"
      "--smart-case"
    ];
  };

  programs.vscode = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      ms-vscode-remote.remote-containers
    ];
  };


  programs.fzf = {
    enable = true;
    package = stablepkgs.fzf;
    enableBashIntegration = true;
  };

  programs.bat = {
    enable = true;
    package = stablepkgs.bat;
    config = {
      theme = "ansi";
    };
  };

  programs.git = {
    enable = true;
    package = stablepkgs.git;
    userName = "Sebastian";
    userEmail = "sebastian@sebastian.software";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

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
          Restart = "always";
          RestartSec = 58;
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
          Environment = [ "PATH=$PATH" "OLLAMA_ORIGINS=*.typingmind.com" "OLLAMA_HOST=localhost"];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
