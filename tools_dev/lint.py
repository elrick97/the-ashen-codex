#!/usr/bin/env python3
"""GDScript lint via Godot's own language server.

Starts the editor headless with the GDScript LSP, opens every project .gd file
(except addons/ and probe folders) and prints each diagnostic Godot reports
(errors and warnings, including untyped declarations). Exit code = number of
diagnostics, so 0 means clean.

Usage: python3 tools_dev/lint.py [--port 6011] [paths...]
"""
import json
import os
import socket
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.path.join(ROOT, "tools_dev", "godot.sh")
SKIP_DIRS = {"addons", ".godot", ".tools", ".git", "probe_tmp"}


def find_scripts(paths):
    out = []
    roots = paths or [ROOT]
    for base in roots:
        base = os.path.abspath(base)
        if base.endswith(".gd"):
            out.append(base)
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for f in filenames:
                if f.endswith(".gd"):
                    out.append(os.path.join(dirpath, f))
    return sorted(out)


class Lsp:
    def __init__(self, port):
        self.sock = None
        deadline = time.time() + 120
        while time.time() < deadline:
            try:
                self.sock = socket.create_connection(("127.0.0.1", port), timeout=5)
                break
            except OSError:
                time.sleep(0.5)
        if self.sock is None:
            raise SystemExit("lint: could not connect to the Godot LSP")
        self.sock.settimeout(0.5)
        self.buf = b""
        self.next_id = 1

    def send(self, method, params, is_request=False):
        msg = {"jsonrpc": "2.0", "method": method, "params": params}
        if is_request:
            msg["id"] = self.next_id
            self.next_id += 1
        body = json.dumps(msg).encode("utf-8")
        self.sock.sendall(b"Content-Length: %d\r\n\r\n" % len(body) + body)
        return msg.get("id")

    def read_messages(self, seconds):
        msgs = []
        end = time.time() + seconds
        while time.time() < end:
            try:
                chunk = self.sock.recv(65536)
                if not chunk:
                    break
                self.buf += chunk
            except socket.timeout:
                pass
            while True:
                sep = self.buf.find(b"\r\n\r\n")
                if sep < 0:
                    break
                header = self.buf[:sep].decode("ascii", "replace")
                length = 0
                for line in header.split("\r\n"):
                    if line.lower().startswith("content-length:"):
                        length = int(line.split(":")[1].strip())
                if len(self.buf) < sep + 4 + length:
                    break
                body = self.buf[sep + 4: sep + 4 + length]
                self.buf = self.buf[sep + 4 + length:]
                try:
                    msgs.append(json.loads(body.decode("utf-8")))
                except ValueError:
                    pass
        return msgs


def main():
    args = sys.argv[1:]
    port = 6011
    if "--port" in args:
        i = args.index("--port")
        port = int(args[i + 1])
        del args[i:i + 2]
    scripts = find_scripts(args)
    proc = subprocess.Popen(
        [GODOT, "--headless", "--editor", "--path", ROOT, "--lsp-port", str(port)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        lsp = Lsp(port)
        root_uri = "file://" + ROOT
        lsp.send("initialize", {"processId": os.getpid(), "rootUri": root_uri,
                                "capabilities": {}}, is_request=True)
        lsp.read_messages(3)
        lsp.send("initialized", {})
        lsp.read_messages(1)
        diags = {}
        for path in scripts:
            uri = "file://" + path
            with open(path, "r", encoding="utf-8") as fh:
                text = fh.read()
            lsp.send("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "gdscript", "version": 1, "text": text}})
            for m in lsp.read_messages(0.4):
                if m.get("method") == "textDocument/publishDiagnostics":
                    p = m["params"]
                    diags[p["uri"]] = p.get("diagnostics", [])
        for m in lsp.read_messages(2):
            if m.get("method") == "textDocument/publishDiagnostics":
                p = m["params"]
                diags[p["uri"]] = p.get("diagnostics", [])
        total = 0
        for uri in sorted(diags):
            rel = os.path.relpath(uri[len("file://"):], ROOT)
            for d in diags[uri]:
                sev = {1: "ERROR", 2: "WARNING", 3: "INFO", 4: "HINT"}.get(d.get("severity", 2), "?")
                line = d["range"]["start"]["line"] + 1
                print("%s:%d: %s: %s" % (rel, line, sev, d.get("message", "")))
                total += 1
        print("lint: %d scripts checked, %d diagnostics" % (len(scripts), total))
        return total
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    sys.exit(min(main(), 125))
