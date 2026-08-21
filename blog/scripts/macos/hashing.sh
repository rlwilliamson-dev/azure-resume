# Hashing the same bytes on macOS, to compare with the other two platforms.
#
# One command per line, same shape as a netlab steps file.
#
# This is the one table in the track where all three columns should print the
# same answer, because a digest is arithmetic rather than a policy. The commands
# differ; the output must not.

# Which of the Linux names actually resolve here
which sha256sum shasum

# What the sha256sum on this machine actually is
ls -l "$(which sha256sum)"

# The same twenty-eight bytes the Linux and Windows captures hash
printf 'correct horse battery staple' | shasum -a 256

# And through the openssl Apple ships, since a reader may reach for it
printf 'correct horse battery staple' | /usr/bin/openssl dgst -sha256

# Which algorithms the shipped tool offers, since the algorithm is a choice
shasum --help 2>&1 | grep -iE "^  -a|--algorithm"
