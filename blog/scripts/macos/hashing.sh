# Hashing the same bytes on macOS, to compare with the other two platforms.
#
# One command per line, same shape as a netlab steps file.
#
# This is the one table in the track where all three columns should print the
# same answer, because a digest is arithmetic rather than a policy. The commands
# differ; the output must not. There is no sha256sum here, which is the first
# thing a Linux reader notices.

# The tool that is not here
which sha256sum || echo "not installed"

# The one that is, against the same twenty-eight bytes
printf 'correct horse battery staple' | shasum -a 256

# The same thing with the openssl Apple ships, since a reader may reach for it
printf 'correct horse battery staple' | /usr/bin/openssl dgst -sha256

# Which algorithms the shipped tool offers, since the algorithm is a choice
shasum --help 2>&1 | grep -i "algorithm"
