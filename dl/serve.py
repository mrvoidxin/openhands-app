#!/usr/bin/env python3
"""Tiny static server that serves the built OpenHands APK for download."""
import http.server
import os
import socketserver

PORT = int(os.environ.get("APK_PORT") or os.environ.get("PORT") or "12000")
ROOT = os.path.dirname(os.path.abspath(__file__))

INDEX = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>OpenHands Mobile APK</title>
  <style>
    body { font-family: system-ui, sans-serif; background:#0b0b0f; color:#eee;
           display:flex; min-height:100vh; align-items:center; justify-content:center; margin:0; padding:1.5rem; }
    .card { background:#17171d; padding:2rem 2.5rem; border-radius:16px;
            box-shadow:0 10px 40px rgba(0,0,0,.5); text-align:center; max-width:520px; }
    h1 { margin:0 0 .25rem; font-size:1.5rem; }
    h2 { font-size:1rem; color:#c9c9d1; margin:1.6rem 0 .4rem; text-align:left; }
    p { color:#9aa0a6; font-size:.9rem; }
    a.btn { display:inline-block; margin-top:.4rem; padding:.8rem 1.6rem; border-radius:10px;
            background:#6c5ce7; color:#fff; text-decoration:none; font-weight:600; }
    a.btn:hover { background:#5b4bd6; }
    a.alt { background:#2b2b36; }
    a.alt:hover { background:#3a3a48; }
    code { color:#8ce99a; }
    ul { text-align:left; color:#9aa0a6; font-size:.85rem; padding-left:1.1rem; }
    .meta { font-size:.75rem; color:#6b7280; margin-top:.3rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>OpenHands Mobile</h1>
    <p>Agent Canvas wrapped with Capacitor for Android</p>

    <h2>Signed release build (recommended)</h2>
    <a class="btn" href="/openhands.apk" download>Download APK</a>
    <div class="meta">6.0 MB &middot; version 1.27.1 &middot; md5 0dc5ac1d46002fa75ffa1ceecc37f4c5</div>

    <h2>Debug build</h2>
    <a class="btn alt" href="/openhands-debug.apk" download>Download debug APK</a>
    <div class="meta">7.3 MB &middot; debuggable, verbose logs</div>

    <h2>Mirror</h2>
    <p style="font-size:.85rem">If this page does not load, try the mirror:
      <a style="color:#8ce99a" href="https://work-2-flepgphmcvqhkivx.prod-runtime.all-hands.dev/">work-2 mirror</a>
    </p>

    <h2>Install</h2>
    <ul>
      <li>Allow install from unknown sources for your browser/file manager.</li>
      <li>Open the APK on the phone and install.</li>
      <li>On first launch, add your agent server host + API key (Local or Cloud).</li>
    </ul>
  </div>
</body>
</html>
"""


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            body = INDEX.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)


class ReuseServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with ReuseServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"Serving {ROOT} on port {PORT}", flush=True)
        httpd.serve_forever()
