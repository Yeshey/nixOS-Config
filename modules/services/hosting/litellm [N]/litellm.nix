{ ... }:
{
  flake.modules.nixos.litellm =
    { config, ... }:
    let
      port = 4000; # keep this in sync with `litellmPort` in ollama.nix / openhands.nix
    in
    {
      sops.secrets."gemini_api_key" = { };
      sops.secrets."litellm_master_key" = { };

      sops.templates."litellm.env".content = ''
        GEMINI_API_KEY=${config.sops.placeholder."gemini_api_key"}
        LITELLM_MASTER_KEY=${config.sops.placeholder."litellm_master_key"}
      '';

      systemd.services.litellm.serviceConfig.EnvironmentFile = config.sops.templates."litellm.env".path;
      systemd.tmpfiles.rules = [
        "Z /var/lib/litellm - - - -"
      ];

      networking.firewall.enable = false;

      services.litellm.environment = {
        MAX_RETRY_DELAY = "86400";      # cap real backoff instead of degenerate 8s
        INITIAL_RETRY_DELAY = "60";
        JITTER = "0.75";
      };

      services.litellm = {
        enable = true;
        host = "0.0.0.0";
        port = port;
        openFirewall = true;

        settings = {
          model_list = [
            # https://aistudio.google.com/rate-limit
            # track https://github.com/BerriAI/litellm/issues/14398
            {
              model_name = "gemini-3.6-flash";
              litellm_params = {
                model = "gemini/gemini-3.6-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.7-flash";
              litellm_params = {
                model = "gemini/gemini-3.7-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.8-flash";
              litellm_params = {
                model = "gemini/gemini-3.8-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 4;        # real limit 5 — buffer of 1
                tpm = 225000;   # real limit 250K — ~10% buffer
              };
            }
            {
              model_name = "gemini-3.5-flash-lite";
              litellm_params = {
                model = "gemini/gemini-3.5-flash-lite";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 13;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }
            {
              model_name = "gemini-3.5-flash";
              litellm_params = {
                model = "gemini/gemini-3.5-flash";
                api_key = "os.environ/GEMINI_API_KEY";
                rpm = 13;       # real limit 15
                tpm = 225000;   # real limit 250K
              };
            }
            {
              # test model — routes to local flask hang server, litellm host+port
              model_name = "hang-test";
              litellm_params = {
                model = "openai/hang-test";
                api_base = "http://127.0.0.1:5011/v1";
                api_key = "sk-test";   # openai provider needs non-empty key, flask ignores it
                timeout = 999999;           # seconds — testing value, raise/remove once confirmed
              };
            }
            {
              # test model — routes to local flask hang server, litellm host+port
              model_name = "rate-limit-test";
              litellm_params = {
                model = "openai/rate-limit-test";
                api_base = "http://127.0.0.1:5011/v1";
                api_key = "sk-test";   # openai provider needs non-empty key, flask ignores it
                timeout = 999999;           # seconds — testing value, raise/remove once confirmed
              };
            }
            {
              # test model — routes to local flask hang server, litellm host+port
              model_name = "delay-test";
              litellm_params = {
                model = "openai/delay-test";
                api_base = "http://127.0.0.1:5011/v1";
                api_key = "sk-test";   # openai provider needs non-empty key, flask ignores it
                timeout = 999999;           # seconds — testing value, raise/remove once confirmed
              };
            }
            {
              # test model — routes to local flask hang server, litellm host+port
              model_name = "cycle-test";
              litellm_params = {
                model = "openai/cycle-test";
                api_base = "http://127.0.0.1:5011/v1";
                api_key = "sk-test";   # openai provider needs non-empty key, flask ignores it
                timeout = 999999;           # seconds — testing value, raise/remove once confirmed
              };
            }
          ];

          router_settings = {
            optional_pre_call_checks = [ "enforce_model_rate_limits" ];
            num_retries = 100;           # <- catch-all for exception types not in retry_policy
            allowed_fails = 100;
            cooldown_time = 86400;
            retry_policy = {
              RateLimitErrorRetries = 100;
              TimeoutErrorRetries = 100;
              InternalServerErrorRetries = 100;
              BadRequestErrorRetries = 100;
              AuthenticationErrorRetries = 100;
              ContentPolicyViolationErrorRetries = 100;
            };
          };
        };
      };
    };
}

# # hang_server.py

# #!/usr/bin/env python3
# """OpenAI-compatible stub.
# /v1/models responds normal.
# /v1/chat/completions on model 'hang-test' hangs forever, no response.
# /v1/chat/completions on model 'rate-limit-test' returns 429 the first N
# calls (per process), then 200 — watch litellm's retry/backoff timing.
# /v1/chat/completions on model 'delay-test' waits exactly 4 minutes after
# receiving the request, then returns a normal response with content 'Hi'.
# /v1/chat/completions on model 'cycle-test': the first request marks an
# 'ok' time 5 minutes out and is itself failed. Every request before that
# mark fails immediately. The first request to land after the mark
# succeeds with 'Hi' and immediately re-arms the next 5 minute window,
# so the pattern repeats: fail-fail-fail...-succeed, fail-fail-fail...
# -succeed, forever."""

# from flask import Flask, request, jsonify, Response, stream_with_context
# import time
# import json
# import datetime
# import threading

# app = Flask(__name__)

# FAIL_COUNT = 3          # how many 429s before succeeding (rate-limit-test)
# attempts = {"n": 0}      # shared counter, resets on server restart

# DELAY_SECONDS = 4 * 60   # exactly 4 minutes (delay-test)

# CYCLE_SECONDS = 5 * 60   # window length (cycle-test)
# cycle_state = {"next_ok_at": None}   # monotonic time; None = not armed yet
# cycle_lock = threading.Lock()


# # ---------------------------------------------------------------------------
# # Shared response helpers (handle both streamed and non-streamed clients)
# # ---------------------------------------------------------------------------

# def _sse_pack(data: dict) -> str:
#     return f"data: {json.dumps(data)}\n\n"


# def _stream_chat_response(model, content):
#     def generate():
#         created = int(time.time())
#         chunk_id = f"chatcmpl-{int(time.time() * 1000)}"

#         yield _sse_pack({
#             "id": chunk_id,
#             "object": "chat.completion.chunk",
#             "created": created,
#             "model": model,
#             "choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}],
#         })
#         yield _sse_pack({
#             "id": chunk_id,
#             "object": "chat.completion.chunk",
#             "created": created,
#             "model": model,
#             "choices": [{"index": 0, "delta": {"content": content}, "finish_reason": None}],
#         })
#         yield _sse_pack({
#             "id": chunk_id,
#             "object": "chat.completion.chunk",
#             "created": created,
#             "model": model,
#             "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
#         })
#         yield "data: [DONE]\n\n"

#     return Response(stream_with_context(generate()), mimetype="text/event-stream")


# def chat_response(model, content, stream):
#     """Build a normal 200 chat-completion reply, streamed or not, matching
#     what the caller asked for via `"stream": true/false` in the request."""
#     if stream:
#         return _stream_chat_response(model, content)
#     return jsonify({
#         "id": f"chatcmpl-{int(time.time() * 1000)}",
#         "object": "chat.completion",
#         "model": model,
#         "choices": [{
#             "index": 0,
#             "message": {"role": "assistant", "content": content},
#             "finish_reason": "stop",
#         }],
#     })


# @app.route("/v1/models", methods=["GET"])
# @app.route("/models", methods=["GET"])
# def models():
#     return {
#         "object": "list",
#         "data": [
#             {"id": "hang-test", "object": "model", "owned_by": "test"},
#             {"id": "rate-limit-test", "object": "model", "owned_by": "test"},
#             {"id": "delay-test", "object": "model", "owned_by": "test"},
#             {"id": "cycle-test", "object": "model", "owned_by": "test"},
#         ],
#     }


# @app.route("/v1/chat/completions", methods=["POST"])
# @app.route("/chat/completions", methods=["POST"])
# def chat():
#     body = request.get_json(silent=True) or {}
#     model = body.get("model", "")
#     stream = bool(body.get("stream", False))
#     now = time.strftime("%H:%M:%S")

#     if model == "rate-limit-test":
#         attempts["n"] += 1
#         n = attempts["n"]
#         print(f"[{now}] rate-limit-test attempt #{n}")
#         if n <= FAIL_COUNT:
#             return jsonify({
#                 "error": {
#                     "message": "Rate limit exceeded, please retry later.",
#                     "type": "rate_limit_error",
#                     "code": "rate_limit_exceeded",
#                 }
#             }), 429
#         attempts["n"] = 0  # reset for next test run
#         return chat_response(model, f"succeeded on attempt {n}", stream)

#     if model == "delay-test":
#         received_at = time.monotonic()
#         send_at_wall = datetime.datetime.now() + datetime.timedelta(seconds=DELAY_SECONDS)
#         print(
#             f"[{now}] delay-test request received, will respond with 'Hi' "
#             f"in {DELAY_SECONDS} seconds (at {send_at_wall.strftime('%H:%M:%S')})"
#         )

#         while True:
#             elapsed = time.monotonic() - received_at
#             remaining = DELAY_SECONDS - elapsed
#             if remaining <= 0:
#                 break
#             time.sleep(min(remaining, 30))

#         done_now = time.strftime("%H:%M:%S")
#         print(f"[{done_now}] delay-test responding now with 'Hi'")
#         return chat_response(model, "Hi", stream)

#     if model == "cycle-test":
#         now_mono = time.monotonic()

#         with cycle_lock:
#             if cycle_state["next_ok_at"] is None:
#                 # First request ever: arm the window, fail this one too.
#                 cycle_state["next_ok_at"] = now_mono + CYCLE_SECONDS
#                 ok_wall = datetime.datetime.now() + datetime.timedelta(seconds=CYCLE_SECONDS)
#                 print(
#                     f"[{now}] cycle-test armed: failing all requests until "
#                     f"{ok_wall.strftime('%H:%M:%S')} ({CYCLE_SECONDS}s from now)"
#                 )
#                 succeed = False
#             elif now_mono < cycle_state["next_ok_at"]:
#                 remaining = cycle_state["next_ok_at"] - now_mono
#                 succeed = False
#                 print(f"[{now}] cycle-test failing (window reopens in {remaining:.0f}s)")
#             else:
#                 # This request lands after the mark: succeed, then re-arm
#                 # the next window starting from now.
#                 cycle_state["next_ok_at"] = now_mono + CYCLE_SECONDS
#                 ok_wall = datetime.datetime.now() + datetime.timedelta(seconds=CYCLE_SECONDS)
#                 succeed = True
#                 print(
#                     f"[{now}] cycle-test window reached: succeeding with 'Hi', "
#                     f"re-armed — next window opens {ok_wall.strftime('%H:%M:%S')}"
#                 )

#         if not succeed:
#             return jsonify({
#                 "error": {
#                     "message": "Service temporarily unavailable, please retry later.",
#                     "type": "service_unavailable_error",
#                     "code": "service_unavailable",
#                 }
#             }), 503

#         return chat_response(model, "Hi", stream)

#     print(f"[{now}] hang-test request received, hanging forever: {body}")
#     time.sleep(10**9)  # never returns
#     return {}  # unreachable


# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5011, threaded=True)