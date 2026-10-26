#!/usr/bin/env bash

# install once
#brew install mitmproxy

# forward host 0.0.0.0:64343 → IntelliJ 127.0.0.1:64342
mitmdump \
  --mode reverse:http://127.0.0.1:64342 \
  --listen-host 0.0.0.0 \
  --listen-port 64343 \
  --no-http2 \
  --set stream_large_bodies=1