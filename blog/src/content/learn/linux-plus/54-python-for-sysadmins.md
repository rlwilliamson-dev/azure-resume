---
title: "Python for sysadmins"
description: "When a shell script grows structure it cannot carry, Python takes over. The data types worth knowing, why indentation is syntax, and why the system refuses to let you pip install anything."
deck: "Bash stopped being the right tool three loops ago"
track: "linux-plus"
level: "working"
order: 550
objectives:
  - "Say when a task has outgrown a shell script and why"
  - "Read and write a Python script using the four data structures that matter"
  - "Explain why indentation is syntax and read an IndentationError"
  - "Create and use a virtual environment, and say what problem it solves"
  - "Explain what PEP 668 prevents and why the system enforces it"
prerequisites: ["scripts-that-do-real-work"]
tags: ["linux", "linux-plus", "python", "scripting", "automation"]
updated: 2026-08-09
draft: false
examObjectives:
  - exam: "xk0-006"
    domain: "4.0"
    objective: "4.3"
sources:
  - title: "The Python Tutorial"
    url: "https://docs.python.org/3/tutorial/index.html"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
  - title: "venv: Creation of virtual environments"
    url: "https://docs.python.org/3/library/venv.html"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
  - title: "PEP 668: Marking Python base environments as externally managed"
    url: "https://peps.python.org/pep-0668/"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
  - title: "PEP 8: Style Guide for Python Code"
    url: "https://peps.python.org/pep-0008/"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
  - title: "subprocess: Subprocess management"
    url: "https://docs.python.org/3/library/subprocess.html"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
  - title: "argparse: Parser for command-line options"
    url: "https://docs.python.org/3/library/argparse.html"
    publisher: "Python Software Foundation"
    accessed: 2026-08-08
    tier: 1
symptoms:
  - symptom: "error: externally-managed-environment"
    anchor: "the-system-refuses-to-install-anything"
  - symptom: "IndentationError: unindent does not match any outer indentation level"
    anchor: "indentation-is-syntax"
  - symptom: "python: command not found"
    anchor: "python-means-python3-and-python-may-not-exist"
---

> **Before you read.** The disk-check script has grown. It now reads a config file,
> checks eleven filesystems, keeps a running total, formats a table, and posts to a
> webhook. It is four hundred lines of bash with three nested loops and a function
> that returns data by echoing it.
>
> It works. Nobody wants to touch it.
>
> **What exactly did bash run out of?**

Not capability. You can do all of that in bash, and the script proves it. What
it ran out of is **data structures**. Bash has strings, and arrays if you are
careful. It has no dictionary worth the name, no nesting, no way to pass a
structured value into a function or get one back, and no way to parse JSON
without shelling out.

Every one of those four hundred lines exists to work around that.

This lesson is not about learning Python. It is about knowing when the shell has
stopped being the right tool, and about the specific Linux things that make Python
on a server different from Python in a tutorial.

### Some words you will need

<dl class="terms">
<dt>module</dt>
<dd>A Python file you can import. The standard library is hundreds of them.</dd>
<dt>package</dt>
<dd>A distributable collection of modules, installed with <code>pip</code>.</dd>
<dt>virtual environment</dt>
<dd>A private directory with its own Python and its own installed packages.</dd>
<dt>PEP</dt>
<dd>Python Enhancement Proposal. The numbered documents that define the language and its conventions.</dd>
<dt>list</dt>
<dd>An ordered, changeable sequence. <code>["a", "b"]</code>.</dd>
<dt>dictionary</dt>
<dd>Keys mapped to values. <code>{"host": "web01"}</code>. The structure bash does not have.</dd>
</dl>

## What breaks without this

**The shell script becomes unmaintainable long before it becomes wrong.** Four
hundred lines with no structured data is a thing people rewrite rather than edit.

**You parse JSON with `sed`.** Every API, every cloud provider, and every modern
tool speaks JSON, and doing that in the shell means `jq` at best and a regex at
worst.

**You install a package and break the system's own tools.** `pip install` as
root on a distribution-managed Python is how `dnf`, which is itself written in
Python, stops working.

**And the reverse mistake:** using Python for something that was three lines of
shell, which is slower to write, slower to run, and harder for the next person.

## When to switch

The honest boundary, in both directions:

| Reach for the shell when | Reach for Python when |
| --- | --- |
| Running and chaining commands | The data has structure |
| Piping text between tools | You need a dictionary or nesting |
| Under about 50 lines | You are parsing JSON, XML, or CSV |
| Glue between programs | Real error handling matters |
| It must run on a minimal image | Arithmetic beyond integers |
| | You want to test it |

**The signal is not length, it is structure.** A three-hundred-line shell
script that runs commands in sequence is fine. A fifty-line one that keeps
parallel arrays in step, or builds a string that it later splits apart to get
its fields back, has already outgrown the shell. Those are both a dictionary
someone could not write.

**Python is not always available and the shell always is.** A rescue environment, a
minimal container, an initramfs, and a busybox appliance all have `sh` and may have
no Python at all. Anything that has to run when the system is broken should be shell.

## Python means python3, and `python` may not exist

<details class="predict">
<summary>The command <code>python3</code> runs a modern Python. On a current Debian, does a command called plain <code>python</code> also exist?</summary>

```bash
# Debian 13 (trixie), x86_64
$ python3 --version; which python3 python; echo "rc=$?"
Python 3.13.5
/usr/bin/python3
rc=1
```

</details>

**`which` found `python3` and nothing else**, and returned 1 to say so. There is no
`python` on this system.

That is deliberate and now standard. Python 2 reached end of life in 2020, and
rather than repoint `python` at Python 3, which would silently change the
meaning of every existing script, most distributions removed it. Debian ships
a `python-is-python3` package for people who want the alias and does not
install it by default.

**So write `python3` everywhere**: in shebangs, in scripts, in documentation, in
cron entries. `#!/usr/bin/env python3` is the portable form, and a shebang of
`#!/usr/bin/python` is a script that fails on a modern system with
`bad interpreter`.

## The data structures that are the reason you are here

Four types cover nearly all system administration work, and two of them are the
ones bash lacks.

<details class="predict">
<summary>The script prints each value alongside <code>type(value).__name__</code>. Six values are declared: an integer, a float, a string, a boolean, a list, and a dictionary. What will Python call the boolean type: <code>boolean</code>, or something shorter?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat types.py; echo "--- run it ---"; python3 types.py
#!/usr/bin/env python3
count = 42
ratio = 0.75
name = "web01"
up = True
hosts = ["web01", "web02", "db01"]
roles = {"web01": "frontend", "db01": "database"}

for value in (count, ratio, name, up, hosts, roles):
    print(f"{str(value):<40} {type(value).__name__}")

print()
print("third host:      ", hosts[2])
print("web01 role:      ", roles["web01"])
print("db01 in roles?   ", "db01" in roles)
print("unknown, safely: ", roles.get("web99", "unassigned"))
--- run it ---
42                                       int
0.75                                     float
web01                                    str
True                                     bool
['web01', 'web02', 'db01']               list
{'web01': 'frontend', 'db01': 'database'} dict

third host:       db01
web01 role:       frontend
db01 in roles?    True
unknown, safely:  unassigned
```

</details>

| Type | Written | Is |
| --- | --- | --- |
| `int` | `42` | A whole number, of unlimited size |
| `float` | `0.75` | A decimal |
| `str` | `"web01"` | Text |
| `bool` | `True`, `False` | **Capitalised.** A common typo. |
| `list` | `["a", "b"]` | Ordered, changeable, indexed from 0 |
| `dict` | `{"k": "v"}` | Keys to values |

**The last two lines of that output are the whole argument for Python.**
`"db01" in roles` asks whether a key exists and returns a boolean. `roles.get("web99",
"unassigned")` looks up a key and supplies a default when it is missing. Both are
one expression, both are obvious to read, and neither has a clean equivalent in
bash.

`hosts[2]` is the third element, because indexing starts at 0. That trips
everybody once and never again.

Two conveniences worth knowing immediately: an f-string, `f"{m} is {pct}%
full"`, interpolates values into text the way the shell does with `"$var"`;
and `{str(value):<40}` inside one pads to 40 characters, which is how the
table above lines up.

## Indentation is syntax

In the shell, indentation is decoration: `fi` ends the `if`. In Python the
indentation **is** the block structure, and there is no closing keyword.

<details class="predict">
<summary>The script below is four lines. The <code>print("done")</code> is indented by two spaces where the line above it is indented by four. Is that a style problem or an error?</summary>

```bash
# Debian 13 (trixie), x86_64
$ cat indent.py; echo "--- run it ---"; python3 indent.py; echo "rc=$?"
#!/usr/bin/env python3
for host in ["web01", "web02"]:
    print("checking", host)
  print("done")
--- run it ---
  File "/root/py/indent.py", line 4
    print("done")
                 ^
IndentationError: unindent does not match any outer indentation level
rc=1
```

</details>

**An error, and the script does not run at all.** Two spaces is neither the four of
the loop body nor the zero of the outer level, so Python cannot tell which block the
line belongs to and refuses to guess.

That strictness is the point. In the shell, badly indented code is misleading;
in Python it is impossible, so the visual structure and the actual structure
cannot disagree.

The rule that avoids every version of this: four spaces per level, never tabs.
PEP 8 says four spaces, and mixing tabs and spaces produces a file that looks
correct and errors, which is worse than one that looks wrong. Configure the
editor once and stop thinking about it.

## A real script

Everything above, doing something useful:

```bash
# Debian 13 (trixie), x86_64
$ cat disks.py
#!/usr/bin/env python3
"""Report filesystems over a usage threshold."""
import shutil

THRESHOLD = 80
MOUNTS = ["/", "/tmp", "/var"]

def usage(path):
    total, used, free = shutil.disk_usage(path)
    return round(used / total * 100)

def main():
    over = {}
    for m in MOUNTS:
        pct = usage(m)
        print(f"{m:<8} {pct:>3}%")
        if pct >= THRESHOLD:
            over[m] = pct
    if over:
        print(f"over threshold: {over}")
    else:
        print("nothing over threshold")

main()
```

**`import shutil` gets disk usage without running `df` and parsing it**, which is
the difference this lesson is about. `shutil.disk_usage` returns three numbers, and
`total, used, free = ...` unpacks them into three variables in one line.

`over` is a dictionary that accumulates, which is the structure bash could not
hold. In shell this needs two parallel arrays kept in step, or a string with a
delimiter that filesystem names must not contain.

`if over:` tests whether the dictionary is empty, because an empty collection
is falsy. That reads naturally and is a genuine idiom rather than a trick.

```bash
# Debian 13 (trixie), x86_64
$ python3 disks.py; echo "rc=$?"
/          7%
/tmp       7%
/var       7%
nothing over threshold
rc=0
```

<details class="deeper">
<summary>If you already administer Linux: the module shadowing that breaks a script for no visible reason</summary>

Naming a script after a standard library module makes Python import *your file*
instead of the library, and the error is baffling because it names a module you did
not write.

This is `disks.py` (the working script from above, unchanged) run in the same
directory as the `types.py` from earlier in this lesson. Its first import is
`shutil`, and it never mentions `types` at all:

```bash
# Debian 13 (trixie), x86_64
$ python3 disks.py; echo "rc=$?"
42                                       int
0.75                                     float
web01                                    str
True                                     bool
['web01', 'web02', 'db01']               list
{'web01': 'frontend', 'db01': 'database'} dict

third host:       db01
web01 role:       frontend
db01 in roles?    True
unknown, safely:  unassigned
Traceback (most recent call last):
  File "/root/py/disks.py", line 3, in <module>
    import shutil
  File "/usr/lib/python3.13/shutil.py", line 10, in <module>
    import fnmatch
  File "/usr/lib/python3.13/fnmatch.py", line 14, in <module>
    import re
  File "/usr/lib/python3.13/re/__init__.py", line 125, in <module>
    import enum
  File "/usr/lib/python3.13/enum.py", line 4, in <module>
    from types import MappingProxyType, DynamicClassAttribute
ImportError: cannot import name 'MappingProxyType' from 'types' (consider renaming '/root/py/types.py' since it has the same name as the standard library module named 'types' and prevents importing that standard library module)
rc=1
```

**Read the top of that output**, because it is the strangest part: `disks.py`
prints the contents of `types.py`. The `import shutil` on line 3 found the
local file, **executed it**, imports run the module, and then failed on the
way back out. So a script you did not run produced output, before an error
naming a module you never imported.

The traceback is the map. `disks.py` imports `shutil`, which imports
`fnmatch`, which imports `re`, which imports `enum`, which imports `types`,
five levels down, and the last one got yours.

Python 3.13 diagnoses it explicitly, which is a relatively recent kindness,
older versions gave a bare `ImportError` with no hint at all, and this cost
people whole afternoons.

The cause is the import path. `sys.path` begins with the script's own
directory, so a local file always wins over the standard library. `shutil`
imports `fnmatch`, which imports `re`, which imports `enum`, which imports
`types`, and gets yours.

The names that catch people are exactly the ones that seem natural for a
sysadmin script: `types.py`, `email.py`, `logging.py`, `select.py`,
`signal.py`, `socket.py`, `queue.py`, `random.py`, `string.py`, `time.py`,
`test.py`, `json.py`, `csv.py`, `platform.py`, `copy.py`, `os.py`, `io.py`.

Check before naming a file:

```
python3 -c "import types; print(types.__file__)"
python3 -c "help('modules')" | head -40
```

The first prints the path of the module that name currently resolves to; if it is
in your directory rather than under `/usr/lib/python3*/`, you have shadowed it.

**A related version bites with `__pycache__`.** Renaming the offending file leaves
a compiled `types.cpython-313.pyc` behind, and while Python usually notices, a
stale cache in a directory you copied between machines can keep the shadow alive.
Deleting `__pycache__` is the second thing to try.

**The general defence is not to run scripts from a directory full of other things.**
A script in `/usr/local/bin` with a name like `check-disks` has no extension, cannot
shadow anything, and is what the file should be called anyway.

</details>

## The system refuses to install anything

This is the Linux-specific part, and it is the thing most likely to stop you.

<details class="predict">
<summary>You want the <code>requests</code> library, so you run <code>pip3 install requests</code> as root. On a current Debian, what happens?</summary>

```bash
# Debian 13 (trixie), x86_64
$ pip3 install requests 2>&1 | tail -4; echo "rc=$?"
    See /usr/share/doc/python3.13/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
rc=0
```

</details>

**It refuses**, and the refusal is a feature. This is PEP 668, and every current
distribution implements it.

The reason is that the system Python is a system component. `dnf`,
`firewalld`, `cloud-init`, `sos`, `netplan`, and `apt`'s own helpers are
written in Python and import from the same site-packages directory `pip` would
write to. Installing a library that upgrades a shared dependency can break the
package manager, leaving a machine that cannot install the fix.

`--break-system-packages` exists and is named honestly. It is there for people
who understand what they are overriding, and the name is the documentation.

The correct answer is a virtual environment, which is a private directory with
its own Python and its own packages:

```bash
# Debian 13 (trixie), x86_64
$ python3 -m venv /root/venv; . /root/venv/bin/activate; which python3; python3 -m pip install -q requests && python3 -c "import requests; print(requests.__version__)"; deactivate; python3 -c "import requests" 2>&1 | tail -1
/root/venv/bin/python3
2.34.2
ModuleNotFoundError: No module named 'requests'
```

Read those three lines as the whole story. After activating, `python3` is
`/root/venv/bin/python3` rather than `/usr/bin/python3`. `requests` installs
and imports at version 2.34.2. After `deactivate`, importing it fails, because
the system Python never had it and was never touched.

`activate` is not magic, which is worth knowing: it prepends the venv's `bin`
to `$PATH` and sets `VIRTUAL_ENV`. That is all. Which means a cron job or a
systemd unit does not need to activate anything, it just calls the interpreter
directly:

```
/opt/myapp/venv/bin/python3 /opt/myapp/check.py
```

That is the form to use in automation, because it depends on no shell state.

| Approach | Use for |
| --- | --- |
| `apt install python3-requests` | A dependency the distribution packages. **Prefer this.** |
| `python3 -m venv` | An application with its own dependencies |
| `pipx install` | A command-line tool, isolated automatically |
| `--break-system-packages` | Almost never |

**The first row is easy to forget.** `python3-requests`, `python3-yaml`, and
`python3-boto3` are all packaged, get security updates from the distribution, and
need no venv at all. For a script using only well-known libraries, that is the
lowest-maintenance answer.

<details class="deeper">
<summary>If you already administer Linux: running commands from Python without opening a shell injection hole</summary>

Most sysadmin Python calls out to other programs eventually, and the module for it
has one dangerous option that a lot of examples use.

**The safe form passes a list**, so there is no shell and nothing to inject:

```python
import subprocess

result = subprocess.run(
    ["systemctl", "is-active", unit],
    capture_output=True, text=True, timeout=10,
)
if result.returncode != 0:
    print(f"{unit} is {result.stdout.strip()}")
```

Each element is one argument. A `unit` value of `nginx; rm -rf /` is passed to
`systemctl` as a single, very strange unit name, and nothing executes it.

**`shell=True` is the hole.** With it, the whole string goes to `/bin/sh`, so the
same value runs `rm -rf /`. The rule is simple: **never use `shell=True` with a
value you did not write literally.** If you need a pipeline, either build it with
two `subprocess` calls connected by `stdout=subprocess.PIPE`, or accept that you
have chosen a shell script.

Three arguments that matter and are easy to omit:

- **`timeout=`**, without it, a hung command hangs your script forever. There
  is no default.
- **`text=True`**, without it you get bytes and have to decode them, and the
  resulting `TypeError` comparing bytes to a string is a common confusion.
- **`check=True`**, raises `CalledProcessError` on failure instead of
  returning silently. It is the `set -e` of `subprocess`, and leaving it off
  is why scripts carry on after a command failed.

Prefer not calling out at all. A large share of shell-outs have a standard
library equivalent that is faster, has no parsing, and cannot fail on locale:

| Instead of | Use |
| --- | --- |
| `df` | `shutil.disk_usage()` |
| `hostname` | `socket.gethostname()` |
| `ls` | `os.listdir()`, `pathlib.Path.iterdir()` |
| `mkdir -p` | `Path(p).mkdir(parents=True, exist_ok=True)` |
| `cp`, `mv`, `rm -r` | `shutil.copy2`, `shutil.move`, `shutil.rmtree` |
| `curl` | `urllib.request`, or `requests` |
| `date` | `datetime` |

And `os.system()` should never appear in new code. It runs through a shell,
gives you no way to capture output, and returns a wait status rather than an
exit code, so `if os.system(cmd):` is testing the wrong number.

</details>

<details class="deeper">
<summary>If you already administer Linux: handling failure, and the four exceptions a sysadmin script actually meets</summary>

Shell scripts check exit statuses. Python raises exceptions, and the
difference is that an unhandled one stops the script with a traceback, which
is the right default and the wrong thing to show a person at 3am.

**The four that come up constantly:**

| Exception | From |
| --- | --- |
| `FileNotFoundError` | Opening a path that is not there, **or running a command that is not installed** |
| `PermissionError` | Opening something you may not read or write |
| `KeyError` | A dictionary key that does not exist |
| `subprocess.CalledProcessError` | A command that exited non-zero, with `check=True` |

**Catch narrowly and act, or do not catch at all:**

```python
try:
    with open("/etc/myapp.conf") as fh:
        config = fh.read()
except FileNotFoundError:
    config = ""                        # a missing config is fine, use defaults
except PermissionError as err:
    sys.exit(f"cannot read config: {err}")
```

Two failures, two different correct responses. A bare `except:` would treat
them identically, and would also swallow `KeyboardInterrupt`, so Ctrl+C stops
working, which is a genuinely infuriating bug to inherit.

**`except Exception:` is the acceptable broad form** when you must log and continue,
because it does not catch `SystemExit` or `KeyboardInterrupt`. A bare `except:`
catches those too and should not appear in anything you write.

For dictionaries, prefer not raising at all. `roles.get(host, "unknown")` is
better than a `try`/`except KeyError` around `roles[host]`, and it is why the
`.get()` in the capture above is worth noticing.

Two habits that make failures readable:

`sys.exit("message")` prints the message to stderr and exits 1, which is far better
than `print()` followed by `sys.exit(1)` and much better than an uncaught traceback.
A person sees one line naming the problem.

**`with open(...) as fh:` closes the file even when an exception is raised**,
which is the same job the `trap ... EXIT` did in the shell lesson. Anything
holding a resource (a file, a lock, a connection) belongs in a `with` block
for exactly that reason.

**And keep the traceback when you are debugging.** It names the file, the line, and
the chain of calls, which is more than any shell script gives you. Catching too
early and printing a friendly message is how people lose the only useful diagnostic
they had. Log it with `logging.exception()`, which records the traceback and carries
on, rather than discarding it.

</details>

## Style, because somebody else will read it

PEP 8 is the style guide, and the parts that matter day to day are few:

| Convention | Example |
| --- | --- |
| Four spaces per indent level | Never tabs |
| `snake_case` for variables and functions | `check_disk`, `mount_point` |
| `UPPER_CASE` for constants | `THRESHOLD = 80` |
| Two blank lines between top-level functions | |
| Lines under 79 characters | Or 88, if the team uses `black` |
| A docstring as the first line of a module or function | `"""What this does."""` |

**Nobody applies these by hand.** `black` reformats a file to a consistent style and
ends the argument; `ruff` or `flake8` finds unused imports, undefined names, and
shadowed builtins. Both are worth running before anything you expect to keep.

**The docstring is the one worth doing deliberately.** `disks.py` above starts with
`"""Report filesystems over a usage threshold."""`, which `help()` and every editor
will show, and which answers the question a person opening an unfamiliar script
actually has.

## Across distributions

| | RHEL family | Debian family |
| --- | --- | --- |
| Interpreter package | `python3` | `python3` |
| `python` alias | `python-unversioned-command` | `python-is-python3` |
| venv module | Included | **`python3-venv`, installed separately** |
| pip | `python3-pip` | `python3-pip` |
| PEP 668 enforced | Yes | Yes |
| Library packages | `python3-requests` | `python3-requests` |

**That third row catches people on Debian and Ubuntu.** `python3 -m venv` fails with
a message about `ensurepip` being unavailable until `python3-venv` is installed,
which is surprising because `venv` is part of the standard library everywhere else.

**Both families use the system Python for their own tooling**, which is why both
enforce PEP 668. On RHEL, `dnf` is written in Python; on Debian, so are large parts
of the installer and `unattended-upgrades`.

## Prove it

```
# Which interpreter, and is there a bare python
python3 --version
which python3 python

# Does it parse, without running it
python3 -m py_compile script.py

# What is this name actually importing
python3 -c "import types; print(types.__file__)"

# Am I in a virtual environment
echo "$VIRTUAL_ENV"
python3 -c "import sys; print(sys.prefix)"

# What is installed here
python3 -m pip list
```

**`python3 -m py_compile` is the equivalent of `bash -n`** and costs nothing. It
catches syntax and indentation errors without executing a line, which matters more
in Python than in shell because a syntax error anywhere stops the whole file.

## What trips people up

### 1. `python: command not found`

There is no bare `python` on current distributions, deliberately, because
repointing it at Python 3 would silently change the meaning of old scripts.

Write `python3`. In a shebang, `#!/usr/bin/env python3`.

### 2. `IndentationError`

Indentation is the block structure, so it has to be consistent. Mixing tabs and
spaces produces a file that looks right and errors.

Four spaces, never tabs, set in the editor once.

### 3. `error: externally-managed-environment`

PEP 668 stopping you from modifying the Python that `dnf` and `apt` depend on.

Use a venv, or install the distribution's `python3-<name>` package.
`--break-system-packages` is named after what it does.

### 4. A script named after a standard library module

`types.py`, `logging.py`, `socket.py` in your working directory shadow the real
module, because the script's own directory is first on `sys.path`.

The error names a module you did not write. Rename the file and remove
`__pycache__`.

### 5. `shell=True` in `subprocess`

Passes the whole string to `/bin/sh`, so any value you did not write literally is
executed. Pass a list instead.

Also add `timeout=`, `text=True`, and `check=True`, none of which are defaults.

### 6. Reaching for Python when the shell was right

Three commands in sequence is a shell script. Python for that is slower to write,
slower to run, and unavailable in a rescue environment.

## Work it through

A monitoring script in bash has grown to 400 lines. It reads a config file
listing hosts and thresholds, checks each, and posts a JSON summary to a
webhook. The current version keeps three parallel arrays (hostnames,
thresholds, and results) and indexes them by number.

Is that a rewrite, and what would you actually change?

Reason it out before reading on.

**The parallel arrays are the diagnosis.** Three arrays indexed by the same number
are a dictionary somebody could not write. Every operation on them has to touch all
three consistently, and any insertion, deletion, or sort has to be done three times
in step. That is not a style preference; it is a data structure the language cannot
express, being emulated by hand.

The JSON is the second signal. Building JSON by string concatenation in bash
means every value needs escaping that nothing checks, and one host with a
quote in its name produces malformed output that the webhook rejects with a
message about column 47.

But "rewrite it in Python" is the wrong answer, and this is the part worth
getting right. A 400-line rewrite is a large change with no behavioural
benefit, tested against nothing, replacing something that currently works.

**The proportionate version:**

- **Move the parts with structure**, not the whole thing. The config parsing and
  the JSON assembly become a Python script; the shell script calls it. Each half
  then does what its language is good at.
- **Or keep it in shell and use `jq`** for the JSON, if that is the only structured
  part. `jq -n --arg host "$h" '{host: $host}'` escapes correctly and is a much
  smaller change.
- **Rewrite wholesale only if it is being substantially changed anyway.** A rewrite
  bundled with a feature is testable against the feature; a rewrite for its own sake
  is a lot of risk for a tidier file.

The point worth extracting: **the trigger for changing language is the shape of the
data, not the size of the file.** Four hundred lines of sequential commands is fine.
Fifty lines keeping three arrays in step is not, and the fix may be fifty lines of
Python called from the shell rather than four hundred lines of anything.

## Try it

Optional, and everything is safe.

1. `python3 --version; which python`. Note the second one fails.
2. Write `disks.py` from this lesson and run it.
3. Change the indentation of one line by two spaces and run it again. Read the
   error.
4. `pip3 install requests` and read the refusal.
5. `python3 -m venv /tmp/v && . /tmp/v/bin/activate && which python3`.
6. `pip install requests` inside it, then `deactivate` and try to import it.
7. Create a file called `socket.py` containing `print("hi")`, then run
   `python3 -c "import socket; print(socket.gethostname())"` in that directory.
8. Delete it, remove `__pycache__`, and try again.

**Verification step.** You have it when you can say what `activate` actually
changes, and therefore why a cron job does not need it.

## Check yourself

<details class="qa">
<summary><code>pip3 install requests</code> fails with <code>externally-managed-environment</code>. What is being protected, and what are the three legitimate ways forward?</summary>

**The distribution's own Python.** `dnf`, `apt`'s helpers, `firewalld`,
`cloud-init`, and `sos` are written in Python and import from the same
site-packages directory `pip` would write into. A library that upgrades a
shared dependency can break the package manager, and then you have a machine
that cannot install the fix.

That is PEP 668, and every current distribution implements it.

**The three ways forward, best first:**

Install the distribution's package. `apt install python3-requests` or `dnf
install python3-requests`. It is tested against that Python, gets security
updates through the normal channel, and needs no isolation.

Create a virtual environment. `python3 -m venv /opt/myapp/venv` gives the
application its own interpreter and its own packages, entirely separate from
the system's. For anything with dependencies the distribution does not
package, this is the answer.

**`pipx install`** for a command-line tool rather than a library, which creates the
venv for you and puts the entry point on `$PATH`.

`--break-system-packages` is the fourth and is named after what it does. It
exists for people who understand exactly what they are overriding.

The related thing worth knowing: in automation you do not activate a venv. Call
`/opt/myapp/venv/bin/python3` directly, because `activate` only edits `$PATH` and a
systemd unit has no shell to edit.

</details>

<details class="qa">
<summary>A script fails with <code>ImportError</code> naming a standard library module it never mentions. What is the likely cause?</summary>

**A file in the script's directory has the same name as a standard library
module**, so Python imports yours instead.

`sys.path` begins with the directory of the script being run, which means a
local file always wins. A file called `types.py` breaks anything that imports
`shutil`, because `shutil` imports `fnmatch`, which imports `re`, which
imports `enum`, which imports `types`, and gets yours.

**The names that catch people are the natural ones for sysadmin work:**
`logging.py`, `socket.py`, `select.py`, `signal.py`, `queue.py`, `json.py`,
`csv.py`, `time.py`, `string.py`, `platform.py`, `test.py`.

**Confirming it takes one command:**

```
python3 -c "import types; print(types.__file__)"
```

If that path is in your working directory rather than under
`/usr/lib/python3*/`, you have shadowed it. Python 3.13 also says so directly
in the error, suggesting you rename the file, older versions gave a bare
`ImportError` with no hint.

**Rename the file, and delete `__pycache__`**, because a stale compiled copy can
keep the shadow alive.

The habit that avoids it entirely: put scripts in `/usr/local/bin` with a name like
`check-disks` and no `.py` extension. A file that is not importable cannot shadow
anything.

</details>

<details class="qa">
<summary>Why is <code>subprocess.run(cmd, shell=True)</code> dangerous, and what are the two other arguments people forget?</summary>

**With `shell=True` the whole command is a string handed to `/bin/sh`**, so any
value interpolated into it is executed as shell code. A hostname of
`web01; rm -rf /` does exactly what it says.

**Passing a list has no shell at all:**

```python
subprocess.run(["systemctl", "is-active", unit], check=True, timeout=10, text=True)
```

Each element is one argument, delivered directly to `execve`. The same malicious
value becomes a single, strange unit name and nothing executes it.

The rule: **never use `shell=True` with a value you did not write literally.** If
you need a pipeline, connect two `subprocess` calls with
`stdout=subprocess.PIPE`, or accept that this task was a shell script.

**The two forgotten arguments:**

**`timeout=`** has no default, so a hung command hangs your script forever. In a
monitoring script run from cron, that is a process that accumulates one copy per run
until the machine falls over.

**`check=True`** raises on a non-zero exit instead of returning quietly.
Without it the script carries on as though the command worked, the same
failure as a shell script without `set -e`.

`text=True` is the third, and without it you get bytes, which produces a confusing
`TypeError` the first time you compare the output to a string.

**And `os.system()` should not appear in new code**: it uses a shell, cannot capture
output, and returns a wait status rather than an exit code, so `if os.system(cmd):`
tests the wrong number.

</details>

<details class="qa">
<summary>A colleague wants to rewrite a 400-line bash script in Python because it is long. Is length the right trigger, and what is?</summary>

**Length is not the trigger. Structure is.**

Four hundred lines of sequential commands (run this, check the status, run
that) is a perfectly good shell script, and rewriting it in Python makes it
slower to run, longer to write, and unavailable in a rescue environment.

**The real signals are all about data the shell cannot hold:**

- **Parallel arrays indexed by the same number.** Three arrays kept in step are a
  dictionary somebody could not write, and every operation has to touch all three.
- **Building a string to split it apart later** to get the fields back.
- **Parsing or producing JSON, XML, or CSV.** Doing that by concatenation means
  escaping that nothing checks.
- **Arithmetic beyond integers**, since the shell has no floats.
- **Wanting to test it.**

**And the answer is usually not a full rewrite either.** Move the part with
the structure (the config parsing, the JSON assembly) into a small Python
script the shell calls. Each language then does what it is good at, and the
change is small enough to review.

The counter-signal is worth remembering too: **anything that must run when the
system is broken should be shell.** A rescue shell, an initramfs, a minimal
container, and a busybox appliance all have `sh` and may have no Python at all.

</details>

<details class="qa">
<summary>What does <code>source venv/bin/activate</code> actually change, and why does a systemd unit not need it?</summary>

**It edits `$PATH` and sets `VIRTUAL_ENV`.** That is essentially all. It prepends
the venv's `bin` directory so that typing `python3` or `pip` finds the venv's copies
rather than `/usr/bin`, and it changes the prompt so you can see which environment
you are in.

There is no other state and no daemon. Which means:

**A systemd unit or a cron entry should call the interpreter directly:**

```
ExecStart=/opt/myapp/venv/bin/python3 /opt/myapp/check.py
```

The venv's `python3` knows its own `sys.prefix` from its location, so it finds the
venv's packages without any environment variable being set. Activation is a
convenience for interactive shells, not a requirement.

**Trying to activate in automation is where things go wrong**, because a
systemd unit has no shell to source into, `ExecStart=source ...` fails
outright, and a cron entry running `source activate && python3 script.py`
depends on cron's shell being one that has `source`, which under `/bin/sh` it
is not.

**To check where you are:**

```
echo "$VIRTUAL_ENV"
python3 -c "import sys; print(sys.prefix)"
```

The second works even when the variable is not set, which is exactly the automation
case.

</details>

## References

- [The Python Tutorial](https://docs.python.org/3/tutorial/index.html) - Python Software Foundation. Accessed 2026-08-08.
- [venv: Creation of virtual environments](https://docs.python.org/3/library/venv.html) - Python Software Foundation. Accessed 2026-08-08.
- [PEP 668: Marking Python base environments as externally managed](https://peps.python.org/pep-0668/) - Python Software Foundation. Accessed 2026-08-08.
- [PEP 8: Style Guide for Python Code](https://peps.python.org/pep-0008/) - Python Software Foundation. Accessed 2026-08-08.
- [subprocess: Subprocess management](https://docs.python.org/3/library/subprocess.html) - Python Software Foundation. Accessed 2026-08-08.
- [argparse: Parser for command-line options](https://docs.python.org/3/library/argparse.html) - Python Software Foundation. Accessed 2026-08-08.

Every block above with a distribution and architecture header was captured by running the command on a Debian 13 (trixie) container. Blocks without one are illustrative.
