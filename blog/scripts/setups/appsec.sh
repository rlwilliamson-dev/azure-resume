#!/usr/bin/env sh
# A static analyser and one small program with real defects in it, so a topic can
# show what static analysis finds and what it cannot see.
#
# The program is deliberately bad and deliberately short. Every defect in it is a
# category the objective names, and one of them is invisible to the analyser,
# which is the point of running it.
set -e
dnf -q -y install python3-pip gnupg2 >/dev/null 2>&1
pip3 -q install bandit >/dev/null 2>&1
mkdir -p /srv/app
cat > /srv/app/handler.py <<'PY'
import hashlib
import os
import sqlite3
import subprocess


def store_password(username, password):
    digest = hashlib.md5(password.encode()).hexdigest()
    return (username, digest)


def find_user(conn, name):
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE name = '%s'" % name)
    return cur.fetchall()


def run_report(report_name):
    subprocess.call("generate-report " + report_name, shell=True)


def set_session(response, token):
    response.headers["Set-Cookie"] = "session=%s; Path=/" % token


def is_admin(user):
    return user.get("role") == "admin" or user.get("is_admin")
PY
# A short reader for bandit's JSON, so the captured command stays readable. It
# prints what was flagged and then the two lines the analyser had nothing to say
# about, which is the half of the topic a scanner cannot cover.
cat > /srv/what-it-missed.py <<'PY'
import json
import sys

report = json.load(sys.stdin)
flagged = {r["line_number"] for r in report["results"]}

print("issues found:", len(report["results"]))
for r in report["results"]:
    print(f'  line {r["line_number"]:>2}  {r["issue_severity"]:<6} {r["test_id"]}')

print()
print("lines the analyser had nothing to say about:")
for n, line in enumerate(open("/srv/app/handler.py"), 1):
    if ("Set-Cookie" in line or "is_admin" in line) and n not in flagged:
        print(f"  line {n:>2}  {line.rstrip()}")
PY
