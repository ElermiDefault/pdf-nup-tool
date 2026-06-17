from __future__ import annotations

import os
import signal
import socket
import sys
import threading
import time
import urllib.error
import urllib.request
import webbrowser
from contextlib import suppress
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = "127.0.0.1"
BACKEND_PORT = 8010
LAUNCHER_PORT = 8123
HEARTBEAT_TIMEOUT_SECONDS = 30
STARTUP_TIMEOUT_SECONDS = 60


class LauncherState:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.last_heartbeat: float | None = None
        self.stop_requested = False

    def heartbeat(self) -> None:
        with self.lock:
            self.last_heartbeat = time.time()

    def should_stop_for_missing_heartbeat(self) -> bool:
        with self.lock:
            if self.last_heartbeat is None:
                return False
            return time.time() - self.last_heartbeat > HEARTBEAT_TIMEOUT_SECONDS

    def request_stop(self) -> None:
        with self.lock:
            self.stop_requested = True


def main() -> int:
    resource_dir = resource_root()
    data_dir = user_data_dir()
    configure_stdio(data_dir)
    configure_backend_environment(resource_dir, data_dir)
    ensure_ports_available([BACKEND_PORT, LAUNCHER_PORT])

    state = LauncherState()
    heartbeat_server = start_heartbeat_server(state)
    backend_server, backend_thread = start_backend_server()
    backend_url = f"http://{HOST}:{BACKEND_PORT}"

    try:
        print("Starting PDF N-up Tool...")
        wait_for_url(f"{backend_url}/health", "backend")
        print(f"Opening {backend_url}")
        webbrowser.open(backend_url)
        print("Close the browser page to stop the local service.")

        while True:
            if not backend_thread.is_alive():
                print("Backend stopped unexpectedly.")
                return 1
            if state.should_stop_for_missing_heartbeat():
                print("Frontend page appears closed. Shutting down service.")
                return 0
            with state.lock:
                if state.stop_requested:
                    return 0
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopping PDF N-up Tool...")
        return 0
    finally:
        state.request_stop()
        heartbeat_server.shutdown()
        heartbeat_server.server_close()
        backend_server.should_exit = True
        backend_thread.join(timeout=5)


def resource_root() -> Path:
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS)
    return Path(__file__).resolve().parents[1]


def user_data_dir() -> Path:
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "PDF N-up Tool"
    return Path(os.environ.get("PDFNUPTOOL_DATA_DIR", Path.home() / ".pdf-nup-tool")).expanduser()


def configure_stdio(data_dir: Path) -> None:
    data_dir.mkdir(parents=True, exist_ok=True)
    log_file = (data_dir / "app-launcher.log").open("a", encoding="utf-8", buffering=1)
    sys.stdout = log_file
    sys.stderr = log_file


def configure_backend_environment(resource_dir: Path, data_dir: Path) -> None:
    os.environ["PDFNUPTOOL_BASE_DIR"] = str(resource_dir)
    os.environ["PDFNUPTOOL_DATA_DIR"] = str(data_dir)
    os.environ["PDFNUPTOOL_FRONTEND_DIST_DIR"] = str(resource_dir / "frontend" / "dist")

    backend_dir = resource_dir / "backend"
    if backend_dir.exists():
        sys.path.insert(0, str(backend_dir))


def ensure_ports_available(ports: list[int]) -> None:
    unavailable = [port for port in ports if not is_port_available(port)]
    if unavailable:
        ports_text = ", ".join(str(port) for port in unavailable)
        raise SystemExit(f"Port(s) already in use: {ports_text}. Close those services and try again.")


def is_port_available(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind((HOST, port))
        except OSError:
            return False
    return True


def start_backend_server():
    import uvicorn

    config = uvicorn.Config(
        "app.main:app",
        host=HOST,
        port=BACKEND_PORT,
        log_level="info",
        access_log=True,
    )
    server = uvicorn.Server(config)
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()
    return server, thread


def start_heartbeat_server(state: LauncherState) -> ThreadingHTTPServer:
    allowed_origins = {
        f"http://127.0.0.1:{BACKEND_PORT}",
        f"http://localhost:{BACKEND_PORT}",
    }

    class Handler(BaseHTTPRequestHandler):
        def do_OPTIONS(self) -> None:
            self.send_response(204)
            self.send_cors_headers()
            self.end_headers()

        def do_POST(self) -> None:
            if self.path == "/heartbeat":
                state.heartbeat()
                self.send_response(204)
                self.send_cors_headers()
                self.end_headers()
                return
            self.send_response(404)
            self.send_cors_headers()
            self.end_headers()

        def do_GET(self) -> None:
            if self.path == "/health":
                self.send_response(200)
                self.send_cors_headers()
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(b"ok")
                return
            self.send_response(404)
            self.send_cors_headers()
            self.end_headers()

        def send_cors_headers(self) -> None:
            origin = self.headers.get("Origin")
            if origin in allowed_origins:
                self.send_header("Access-Control-Allow-Origin", origin)
            else:
                self.send_header("Access-Control-Allow-Origin", f"http://{HOST}:{BACKEND_PORT}")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")

        def log_message(self, format: str, *args: object) -> None:
            return

    server = ThreadingHTTPServer((HOST, LAUNCHER_PORT), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def wait_for_url(url: str, label: str) -> None:
    deadline = time.time() + STARTUP_TIMEOUT_SECONDS
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=2) as response:
                if 200 <= response.status < 500:
                    return
        except (TimeoutError, urllib.error.URLError, OSError):
            pass
        time.sleep(0.5)
    raise RuntimeError(f"Timed out waiting for {label} at {url}.")


def handle_signal(signum: int, frame: object) -> None:
    raise KeyboardInterrupt


if __name__ == "__main__":
    with suppress(ValueError):
        signal.signal(signal.SIGTERM, handle_signal)
    raise SystemExit(main())
