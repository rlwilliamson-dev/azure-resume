# Whether a deny list written against filenames can be trusted on this platform.
#
# One command per line, same shape as a netlab steps file.
#
# A directory traversal defence usually inspects the requested path before
# anything opens it, so what matters is how many spellings reach one file. Linux
# resolves dots and symlinks and is otherwise literal about bytes. macOS is not
# literal about bytes, and the two ways it differs are both invisible in a log.

# What the operating system does with dots in a path, before any file is opened
python3 -c 'import os; print(os.path.realpath("/Library/WebServer/Documents/../../../etc/passwd"))'

# Whether the boot volume distinguishes upper case from lower
diskutil info / | grep -i 'case-sensitive'

# Which spellings of one filename reach the same file
d=$(mktemp -d); printf 'contents' > "$d/secret.txt"; for n in secret.txt SECRET.TXT Secret.Txt 'secret.txt ' './secret.txt'; do printf '%-16s %s\n' "$n" "$(cat "$d/$n" 2>/dev/null || echo refused)"; done

# Whether a name typed as one accented character and a name typed as two reach one file
d=$(mktemp -d); printf 'contents' > "$d/$(printf 'caf\xc3\xa9')"; printf 'two code points: %s\n' "$(cat "$d/$(printf 'cafe\xcc\x81')" 2>/dev/null || echo refused)"; ls "$d" | od -c | head -2

# Whether paths that look unrelated reach the same directory
ls -ld /etc /var /tmp
