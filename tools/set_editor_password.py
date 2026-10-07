"""Sets the Island Editor's admin password (web/editor.html) and copies the editor into build/web.
Usage:  python tools/set_editor_password.py "the new password"
Only a SHA-256 hash of the password is stored in the page.
"""
import hashlib, os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "web", "editor.html")
if len(sys.argv) < 2 or not sys.argv[1].strip():
    sys.exit('Usage: python tools/set_editor_password.py "the new password"')
h = hashlib.sha256(sys.argv[1].encode("utf-8")).hexdigest()
s = open(SRC, encoding="utf-8").read()
s = re.sub(r'const PASSWORD_SHA256 = "[0-9a-f]*";', f'const PASSWORD_SHA256 = "{h}";', s)
open(SRC, "w", encoding="utf-8").write(s)
shutil.copy(SRC, os.path.join(ROOT, "build", "web", "editor.html"))
print("Password set, and editor.html copied to build/web.")
