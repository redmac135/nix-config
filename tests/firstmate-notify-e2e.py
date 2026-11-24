#!/usr/bin/env python3
"""Exercise the opt-in notifier in real Pi TUIs using a local fake model.

Requires pi, python3, and node on PATH. No Herdr session or Windows toast is used.
"""

import fcntl
import json
import os
import pathlib
import pty
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = pathlib.Path(__file__).resolve().parents[1]
HOOK = ROOT / "files/firstmate/pi-notify.ts"
PI = shutil.which("pi")


class Model(BaseHTTPRequestHandler):
    def do_POST(self):
        request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        prompt = next(m["content"] for m in reversed(request["messages"]) if m["role"] == "user")
        if isinstance(prompt, list):
            prompt = " ".join(part.get("text", "") for part in prompt)
        response = "MONITOR_NOTIFICATION_HANDLED" if "ack" in prompt else "LAB-RESPONSE: What next?"
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.end_headers()
        for delta, finish in [({"role": "assistant", "content": response}, None), ({}, "stop")]:
            event = {"id": "lab", "object": "chat.completion.chunk", "created": 1, "model": "fake", "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}
            self.wfile.write(("data: " + json.dumps(event) + "\n\n").encode())
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()

    def log_message(self, *_args):
        pass


def run_case(base, server, name, *, cwd, home, load_hook=True, expected=0, prompt="test"):
    agent = base / (name + "-agent")
    agent.mkdir()
    (agent / "models.json").write_text(json.dumps({"providers": {"lab": {
        "baseUrl": f"http://127.0.0.1:{server.server_port}/v1", "api": "openai-completions",
        "apiKey": "dummy", "models": [{"id": "fake"}]
    }}}))
    log = base / (name + "-notifications")
    bin_dir = base / (name + "-bin")
    bin_dir.mkdir()
    fake = bin_dir / "powershell.exe"
    fake.write_text("#!/bin/sh\nprintf 'notification\\n' >> \"$NOTIFY_TEST_LOG\"\n")
    fake.chmod(0o755)
    env = {**os.environ, "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"],
           "FM_HOME": str(home), "WSL_DISTRO_NAME": os.environ.get("WSL_DISTRO_NAME", "test"), "PI_CODING_AGENT_DIR": str(agent),
           "NOTIFY_TEST_LOG": str(log), "TERM": "xterm-256color", "PI_OFFLINE": "1"}
    for key in ("HERDR_ENV", "HERDR_SOCKET_PATH", "HERDR_PANE_ID", "HERDR_TAB_ID", "HERDR_WORKSPACE_ID"):
        env.pop(key, None)
    args = [PI, "--no-extensions", "--no-context-files", "--no-skills", "--no-prompt-templates",
            "--no-mcp", "--no-session", "--no-tools", "--provider", "lab", "--model", "fake", "--offline"]
    if load_hook:
        args += ["-e", str(HOOK)]
    args += [prompt]
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    process = subprocess.Popen(args, cwd=cwd, env=env, stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
    os.close(slave)
    output = b""
    marker = b"MONITOR_NOTIFICATION_HANDLED" if "ack" in prompt else b"LAB-RESPONSE"
    try:
        deadline = time.monotonic() + 20
        seen = None
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.1)
            if ready:
                try:
                    output += os.read(master, 65536)
                except OSError:
                    break
            if marker in output and seen is None:
                seen = time.monotonic()
            if seen is not None and time.monotonic() - seen > 1.5:
                break
            if process.poll() is not None:
                break
        if marker not in output:
            raise AssertionError(f"{name}: no model response: {output[-4000:]!r}")
        count = len(log.read_text().splitlines()) if log.exists() else 0
        if count != expected:
            raise AssertionError(f"{name}: expected {expected} notifications, got {count}: {output[-4000:]!r}")
        print(f"ok - {name}: {count} notification(s)")
    finally:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        os.close(master)


def main():
    if not PI:
        raise SystemExit("pi is required")
    server = ThreadingHTTPServer(("127.0.0.1", 0), Model)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix="fm-notify-e2e-") as tmp:
            base = pathlib.Path(tmp)
            home = base / "primary"
            (home / "bin").mkdir(parents=True)
            (home / "bin/fm-session-start.sh").touch()
            worker = base / "worker"
            worker.mkdir()
            second = base / "secondmate"
            (second / "bin").mkdir(parents=True)
            (second / "bin/fm-session-start.sh").touch()
            (second / ".fm-secondmate-home").touch()
            run_case(base, server, "primary", cwd=home, home=home, expected=1)
            run_case(base, server, "ack", cwd=home, home=home, prompt="ack")
            run_case(base, server, "worker", cwd=worker, home=home)
            run_case(base, server, "secondmate", cwd=second, home=second)
            run_case(base, server, "not-opted-in", cwd=home, home=home, load_hook=False)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
