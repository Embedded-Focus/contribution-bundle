import socket as sock_module
import threading
import time
from argparse import ArgumentParser
from contextlib import closing
from functools import partial
from http.server import SimpleHTTPRequestHandler
from pathlib import Path
from socketserver import TCPServer

from playwright.sync_api import sync_playwright


def get_free_port() -> int:
    """Get an available port by binding to port 0."""
    with closing(sock_module.socket(sock_module.AF_INET, sock_module.SOCK_STREAM)) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def wait_for_server(port: int, timeout: float = 5.0) -> None:
    """
    Wait for HTTP server to be ready by attempting to connect.

    Args:
        port: The port number to check
        timeout: Maximum time to wait in seconds

    Raises:
        TimeoutError: If server doesn't start within timeout
    """
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            with sock_module.create_connection(("127.0.0.1", port), timeout=0.5):
                return
        except (TimeoutError, ConnectionRefusedError, OSError):
            time.sleep(0.1)
    raise TimeoutError(f"Server on port {port} did not start within {timeout}s")


def start_web_server(port: int, directory: str) -> None:
    """
    Start an HTTP server on the specified port serving files from directory.

    Args:
        port: The port number to bind to
        directory: The directory path to serve files from
    """
    handler = partial(SimpleHTTPRequestHandler, directory=directory)
    with TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()


def main() -> None:
    parser = ArgumentParser(description="Generate PDF from a reveal.js presentation")
    parser.add_argument(
        "--output",
        type=str,
        default="/tmp/output.pdf",
        help="Output PDF file path (default: /tmp/output.pdf)",
    )
    parser.add_argument(
        "--serve-dir",
        type=str,
        default=".",
        help="Directory to serve files from (default: current directory)",
    )
    parser.add_argument(
        "--input",
        type=str,
        default="index.html",
        help="HTML file to print relative to serve-dir (default: index.html)",
    )
    args = parser.parse_args()

    serve_dir = Path(args.serve_dir).resolve()
    if not serve_dir.exists():
        raise FileNotFoundError(f"Serve directory does not exist: {serve_dir}")
    if not serve_dir.is_dir():
        raise NotADirectoryError(f"Serve path is not a directory: {serve_dir}")

    tcp_port = get_free_port()
    server_thread = threading.Thread(
        target=start_web_server,
        args=(tcp_port, str(serve_dir)),
        daemon=True,
    )
    server_thread.start()

    wait_for_server(tcp_port)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 3840, "height": 2160})

        try:
            page.goto(f"http://127.0.0.1:{tcp_port}/{args.input}")

            page.keyboard.press("e")

            page.wait_for_load_state("networkidle", timeout=10000)

            page.pdf(
                path=args.output,
                format="A4",
                print_background=True,
            )
        finally:
            browser.close()


if __name__ == "__main__":
    main()
