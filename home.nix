{ config, pkgs, ... }:

let
  sources = import ./nix/sources.nix {};
  stablepkgs = import sources.nixpkgs-stable { config.allowUnfree = true; };
  nixgl = import sources.nixGL {};

in {
  imports = [
    ./modules/neovim.nix
    ./modules/whisper.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "sebastian";
  home.homeDirectory = "/home/sebastian";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release introduces backwards incompatible changes. You should not change this value, even if you update Home Manager. If you do want to update the value, then make sure to first check the Home Manager
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
    (writeShellScriptBin "dvc" ''
      DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock ${pkgs.devcontainer}/bin/devcontainer "$@"
    '')

    postman
    docker-compose
    tcpdump
    wl-clipboard
    parallel
    libtree
    jq
    uv
    niv
    nodenv
    websocat
    simple-http-server
    poweralertd
    nmap
    btop
    gitlab-runner
    aider-chat
    python312Packages.conda
    dust
    imagemagick
    pkgs.devcontainer
    pkgs.cloudflared
    pkgs.codex
  ] ++ (map config.lib.nixGL.wrap [
    pinta
    minder
    slack
    remmina
    flowblade
    wpsoffice
    libreoffice
    pkgs.signal-desktop
    prismlauncher
    inkscape-with-extensions
    krita
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

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
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

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "qtwebengine-5.15.19"
    ];
  };

  systemd.user = {
    services = {

      typingmind-mcp-server = {
        Unit = {
          Description = "TypingMind MCP server";
        };

        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          Environment = [
            "HOSTNAME=localhost"
	          "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${pkgs.nodejs_24}/bin"
          ];
	        EnvironmentFile = "%h/.config/systemd/user/typingmind-mcp-server.env";
          ExecStart = "${pkgs.nodejs_24}/bin/npx -y @typingmind/mcp";

          Restart = "always";
          RestartSec = 57;

          StandardOutput = "journal";
          StandardError  = "journal";

          TimeoutStartSec = "2min";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      codemcp = {
        Unit = {
          Description = "codemcp server";
        };
        Service = {
          ExecStart = "${pkgs.uv}/bin/uvx --from ${sources.codemcp} codemcp serve --port 4081";
          Restart = "always";
          RestartSec = 58;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
