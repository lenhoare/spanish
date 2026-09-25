"""Serve the web build over HTTPS so phones on the same Wi-Fi can play it.

Godot web games need a "secure context" (HTTPS, or localhost). Phones reach this PC by
its network address, so plain HTTP isn't enough. This makes a self-signed certificate
(first run only) and serves build/web on https://<this-PC>:8443

The phone will warn that the connection isn't private (the certificate is home-made):
  - Android Chrome: tap "Advanced" -> "Proceed to ... (unsafe)"
  - iPhone Safari:  tap "Show Details" -> "visit this website"
That's expected and fine on your own Wi-Fi.

Usage:  python tools/serve_https.py
"""
import http.server
import os
import socket
import ssl
import subprocess
import sys
import threading
from functools import partial

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "build", "web")
CERTS = os.path.join(ROOT, "tools", "certs")
PORT = 8443
HTTP_PORT = 8060
OPENSSL_CANDIDATES = [
    r"C:\Program Files\Git\usr\bin\openssl.exe",
    r"C:\Program Files\Git\mingw64\bin\openssl.exe",
    "openssl",
]


def lan_ip() -> str:
    # Connecting a UDP socket sends nothing; it just asks the OS which interface it would use.
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("192.168.1.1", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def make_cert(ip: str) -> tuple[str, str]:
    os.makedirs(CERTS, exist_ok=True)
    cert = os.path.join(CERTS, f"cert-{ip}.pem")
    key = os.path.join(CERTS, f"key-{ip}.pem")
    if os.path.exists(cert) and os.path.exists(key):
        return cert, key
    openssl = next((p for p in OPENSSL_CANDIDATES if p == "openssl" or os.path.exists(p)), "openssl")
    subprocess.run([
        openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes",
        "-keyout", key, "-out", cert, "-days", "825",
        "-subj", "/CN=Lesson Island (home test)",
        "-addext", f"subjectAltName=IP:{ip},IP:127.0.0.1,DNS:localhost",
    ], check=True, capture_output=True)
    return cert, key


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    # Always fetch fresh files, so a rebuilt game or edited lesson shows up on refresh.
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    if not os.path.exists(os.path.join(WEB, "index.html")):
        sys.exit("No web build found in build/web - export the game first (see README).")
    ip = lan_ip()
    cert, key = make_cert(ip)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), partial(NoCacheHandler, directory=WEB))
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    # Plain HTTP too, on all interfaces (secure only on localhost; other machines need HTTPS for full features).
    plain = http.server.ThreadingHTTPServer(("0.0.0.0", HTTP_PORT), partial(NoCacheHandler, directory=WEB))
    threading.Thread(target=plain.serve_forever, daemon=True).start()
    print(f"Serving the game at  https://{ip}:{PORT}  and  http://localhost:{HTTP_PORT}")
    print("Files are sent with no-cache headers, so a normal refresh always gets the latest build.")
    print("On your phone: accept the 'not private' warning once (it's your own certificate).")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
