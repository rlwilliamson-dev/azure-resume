# Two inputs one character apart, and the tools to compare what comes out.
#
# The minimal AlmaLinux image has no diffutils and no python, so both are
# installed here rather than in the command, which keeps the transcript to the
# thing the topic is about.
dnf -q -y install openssl diffutils python3 >/dev/null 2>&1
printf 'correct horse battery staple' > /tmp/a
printf 'correct horse battery stapla' > /tmp/b
