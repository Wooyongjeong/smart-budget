"""Forward an ADB-reversed localhost port to Ollama on a trusted LAN.

Run in a separate terminal, then `adb reverse tcp:11434 tcp:11434`.
The listener is loopback-only and has no authentication; development use only.
"""

import argparse
import select
import socket
import socketserver


class _Relay(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            with socket.create_connection(self.server.target, timeout=5) as remote:
                peers = {self.request: remote, remote: self.request}
                while True:
                    ready, _, _ = select.select(peers, [], [])
                    for source in ready:
                        data = source.recv(65536)
                        if not data:
                            return
                        peers[source].sendall(data)
        except OSError as error:
            print(f"Ollama bridge connection failed: {error}", flush=True)


class _Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host", help="Ollama Mac LAN IP address")
    parser.add_argument("--port", type=int, default=11434)
    args = parser.parse_args()
    with _Server(("127.0.0.1", 11434), _Relay) as server:
        server.target = (args.host, args.port)
        print(f"Ollama USB bridge: 127.0.0.1:11434 -> {args.host}:{args.port}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
