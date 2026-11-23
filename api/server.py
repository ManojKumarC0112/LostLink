#!/usr/bin/env python3
"""
LostLink - Unix & Shell Scripting Campus Lost & Found System
API Bridge: api/server.py
Responsibility: Lightweight bridge passing HTTP requests to Linux Bash scripts
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from socketserver import ThreadingMixIn
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

# Directories
PROJECT_ROOT = Path(__file__).resolve().parent.parent
BACKEND_DIR = PROJECT_ROOT / "backend"
FRONTEND_DIR = PROJECT_ROOT / "frontend"
REPORTS_DIR = PROJECT_ROOT / "reports"
PORT = 5000

# Locate Bash Executable across Windows (Git Bash / WSL) and Linux/macOS
def find_bash():
    if sys.platform == "win32":
        candidates = [
            r"C:\Program Files\Git\bin\bash.exe",
            r"C:\Program Files\Git\usr\bin\bash.exe",
            shutil.which("bash"),
            shutil.which("wsl")
        ]
        for c in candidates:
            if c and os.path.exists(c):
                return c
        return "bash"
    else:
        return shutil.which("bash") or "/bin/bash"

BASH_EXEC = find_bash()

def run_bash_script(script_name, *args):
    """Executes a Bash script and returns stdout/stderr with returncode"""
    script_path = BACKEND_DIR / script_name
    cmd = [BASH_EXEC, str(script_path)] + list(args)
    try:
        res = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd=str(PROJECT_ROOT),
            encoding="utf-8",
            errors="replace"
        )
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, "", str(e)


class LostLinkAPIHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(FRONTEND_DIR), **kwargs)

    def _set_headers(self, status=200, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)

    def _read_body_json(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length > 0:
            body_bytes = self.rfile.read(content_length)
            try:
                data = json.loads(body_bytes.decode("utf-8"))
                if isinstance(data, dict):
                    return {
                        k: (v.replace("\r", "").replace("\n", " ") if isinstance(v, str) else v)
                        for k, v in data.items()
                    }
                return data
            except Exception:
                return {}
        return {}

    def do_GET(self):
        url = urlparse(self.path)
        path = url.path
        params = parse_qs(url.query)

        # API Endpoints routed directly to Bash scripts
        if path == "/api/stats":
            code, out, err = run_bash_script("analytics.sh", "stats", "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else '{"error": "Failed to run analytics"}').encode("utf-8"))
            return

        elif path == "/api/items/lost":
            status = params.get("status", ["all"])[0]
            code, out, err = run_bash_script("record_manager.sh", "list", "lost", status, "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/items/found":
            status = params.get("status", ["all"])[0]
            code, out, err = run_bash_script("record_manager.sh", "list", "found", status, "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/search":
            stype = params.get("type", ["all"])[0]
            kw = params.get("q", [""])[0]
            cat = params.get("category", ["all"])[0]
            loc = params.get("location", ["all"])[0]
            stat = params.get("status", ["all"])[0]
            sort_by = params.get("sort", ["date_desc"])[0]
            code, out, err = run_bash_script("search_engine.sh", "search", stype, kw, cat, loc, stat, sort_by, "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/matches":
            thresh = params.get("threshold", ["25"])[0]
            code, out, err = run_bash_script("matching_engine.sh", "match-all", "--json", thresh)
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/claims":
            status = params.get("status", ["all"])[0]
            code, out, err = run_bash_script("claim_manager.sh", "list", status, "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/system":
            code, out, err = run_bash_script("system_monitor.sh", "status", "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "{}").encode("utf-8"))
            return

        elif path == "/api/backups":
            code, out, err = run_bash_script("backup_restore.sh", "list", "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/logs":
            limit = params.get("limit", ["40"])[0]
            kw = params.get("q", ["all"])[0]
            code, out, err = run_bash_script("audit_logger.sh", "view", limit, kw, "--json")
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else "[]").encode("utf-8"))
            return

        elif path == "/api/reports":
            reports = []
            if REPORTS_DIR.exists():
                for p in sorted(REPORTS_DIR.glob("report_*"), key=lambda x: x.stat().st_mtime, reverse=True):
                    if p.is_file():
                        reports.append({
                            "filename": p.name,
                            "type": "html" if p.suffix == ".html" else "txt",
                            "size": f"{p.stat().st_size / 1024:.1f} KB",
                            "mtime": p.stat().st_mtime,
                            "url": f"/reports/{p.name}"
                        })
            self._set_headers(200)
            self.wfile.write(json.dumps(reports).encode("utf-8"))
            return

        # Direct serving of generated reports (HTML / TXT)
        elif path.startswith("/reports/"):
            rel_file = path[len("/reports/"):]
            target = (REPORTS_DIR / rel_file).resolve()
            if target.is_file() and str(target).startswith(str(REPORTS_DIR.resolve())):
                content_type = "text/html; charset=utf-8" if target.suffix == ".html" else "text/plain; charset=utf-8"
                self._set_headers(200, content_type=content_type)
                with open(target, "rb") as f:
                    self.wfile.write(f.read())
                return
            self._set_headers(404, content_type="text/plain; charset=utf-8")
            self.wfile.write(b"Report not found")
            return

        # Serve Frontend Static Assets
        return super().do_GET()

    def do_POST(self):
        url = urlparse(self.path)
        path = url.path
        body = self._read_body_json()

        if path == "/api/auth/login":
            username = body.get("username", "")
            password = body.get("password", "")
            code, out, err = run_bash_script("record_manager.sh", "auth", username, password, "--json")
            self._set_headers(200 if code == 0 else 401)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/auth/register":
            code, out, err = run_bash_script(
                "record_manager.sh", "register",
                body.get("username", ""),
                body.get("password", ""),
                body.get("full_name", ""),
                body.get("email", ""),
                body.get("role", "student"),
                "--json"
            )
            self._set_headers(200 if code == 0 else 400)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/items/lost":
            code, out, err = run_bash_script(
                "record_manager.sh", "add-lost",
                body.get("title", ""),
                body.get("category", "General"),
                body.get("description", ""),
                body.get("location", ""),
                body.get("date", ""),
                body.get("reported_by", "student"),
                body.get("email", ""),
                body.get("contact_phone", body.get("phone", "+91-9876543210")),
                "--json"
            )
            self._set_headers(200 if code == 0 else 400)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/items/found":
            code, out, err = run_bash_script(
                "record_manager.sh", "add-found",
                body.get("title", ""),
                body.get("category", "General"),
                body.get("description", ""),
                body.get("location", ""),
                body.get("date", ""),
                body.get("reported_by", "security_desk"),
                body.get("email", ""),
                body.get("contact_phone", body.get("phone", "+91-9876543211")),
                "--json"
            )
            self._set_headers(200 if code == 0 else 400)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/claims":
            code, out, err = run_bash_script(
                "claim_manager.sh", "submit",
                body.get("found_item_id", ""),
                body.get("claimed_by", "student"),
                body.get("proof_details", ""),
                body.get("claimant_phone", body.get("phone", "+91-9876543210")),
                "--json"
            )
            self._set_headers(200 if code == 0 else 400)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/claims/review":
            code, out, err = run_bash_script(
                "claim_manager.sh", "review",
                body.get("claim_id", ""),
                body.get("decision", "approve"),
                body.get("reviewer", "admin"),
                body.get("notes", "Reviewed"),
                "--json"
            )
            self._set_headers(200 if code == 0 else 400)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/reports/generate":
            rtype = body.get("type", "daily")
            user = body.get("user", "admin")
            code, out, err = run_bash_script("report_generator.sh", "generate", rtype, "all", user)
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write(json.dumps({"success": code == 0, "output": out}).encode("utf-8"))
            return

        elif path == "/api/backups":
            rdays = str(body.get("retention_days", 7))
            user = body.get("user", "admin")
            code, out, err = run_bash_script("backup_restore.sh", "create", rdays, "--json", user)
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        elif path == "/api/backups/restore":
            target = body.get("filename", "")
            user = body.get("user", "admin")
            code, out, err = run_bash_script("backup_restore.sh", "restore", target, "--json", user)
            self._set_headers(200 if code == 0 else 500)
            self.wfile.write((out if out else '{"success": false}').encode("utf-8"))
            return

        self._set_headers(404)
        self.wfile.write(b'{"error": "Endpoint not found"}')


def run_server():
    server_address = ("", PORT)
    httpd = ThreadedHTTPServer(server_address, LostLinkAPIHandler)
    print("=" * 70)
    print("  LostLink - Unix & Shell Scripting Powered Campus Lost & Found System")
    print(f"  Backend Engine : GNU Bash ({BASH_EXEC})")
    print(f"  Data Storage   : CSV Flat Files ({PROJECT_ROOT / 'database'})")
    print(f"  Web Server URL : http://localhost:{PORT}")
    print("=" * 70)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server gracefully...")
        httpd.server_close()


if __name__ == "__main__":
    run_server()
