{ config, pkgs, ... }:

let
  sources = import ../nix/sources.nix {};
  internalPort = 4078;  # whisper.cpp behind proxy
  publicPort = 4079;    # front-end that clients hit
  modelsListBody = builtins.toJSON {
    object = "list";
    data = [{
      id = "whisper-1";
      object = "model";
      owned_by = "local";
      permission = [];
    }];
  };
  modelBody = builtins.toJSON {
    id = "whisper-1";
    object = "model";
    owned_by = "local";
    permission = [];
  };
caddyfile = pkgs.writeText "whisper-openai.Caddyfile" ''
:${toString publicPort} {
	log {
		output stdout
		format console
		level INFO
	}

	@preflight {
		method OPTIONS
		path /v1/*
	}
	handle @preflight {
		header {
			Access-Control-Allow-Origin "*"
			Access-Control-Allow-Methods "GET, POST, OPTIONS"
			Access-Control-Allow-Headers "{http.request.header.Access-Control-Request-Headers}"
			Access-Control-Allow-Private-Network "true"
			Access-Control-Max-Age "600"
			Vary "Origin, Access-Control-Request-Method, Access-Control-Request-Headers"
		}
		respond "" 204
	}

	# Proxy for audio endpoints
	handle /v1/audio/* {
		reverse_proxy http://127.0.0.1:${toString internalPort}
	}

	# Only set CORS headers when Origin is present; ensure a single ACAO
	@hasOrigin header Origin *
	header @hasOrigin {
		Access-Control-Allow-Origin "*"
		Vary "Origin"
	}

	# Models endpoints (CORS for these too)
	@modelsGET {
		method GET
		path /v1/models
	}
	handle @modelsGET {
		header @hasOrigin
		header Content-Type application/json
		respond <<HEREDOC
			${modelsListBody}
			HEREDOC 200
	}

	@modelGET {
		method GET
		path /v1/models/whisper-1
	}
	handle @modelGET {
		header @hasOrigin
		header Content-Type application/json
		respond <<HEREDOC
			${modelBody}
			HEREDOC 200
	}

	respond /v1/* 404

	respond <<HEREDOC
		{"error":"Not implemented"}
		HEREDOC 200
}
'';

in
{
  # whisper.cpp on internal port
  systemd.user.services.whisper-cpp = {
    Unit = {
      Description = "whisper.cpp server";
      After = "network-online.target";
    };
    Service = {
      ExecStart = "${pkgs.whisper-cpp-vulkan}/bin/whisper-server --model ${sources.whisper-model} --language auto -fa --port ${toString internalPort} --request-path /v1/audio --inference-path /transcriptions";
      Restart = "always";
      RestartSec = 59;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # Caddy front-end using the store Caddyfile
  systemd.user.services.whisper-api = {
    Unit = {
      Description = "OpenAI-compatible proxy for whisper.cpp";
      After = [ "network-online.target" "whisper-cpp.service" ];
      Wants = [ "whisper-cpp.service" ];
    };
    Service = {
      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter caddyfile";
      Restart = "always";
      RestartSec = 3;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
