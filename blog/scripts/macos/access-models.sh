# Which access control model this platform actually implements, read off a file.
#
# One command per line, same shape as a netlab steps file.
#
# macOS carries both models at once: the nine permission bits it inherits from
# Unix, and an ordered access control list on top of them, so a single file can
# be described two ways that do not have to agree.

# A file with ordinary permissions, described the Unix way
touch /tmp/payroll.csv; ls -l /tmp/payroll.csv

# The same file with any access control list shown, which is a separate mechanism
chmod +a "everyone deny delete" /tmp/payroll.csv 2>/dev/null; ls -le /tmp/payroll.csv

# What the two layers disagree about, which the ordinary listing does not show
stat -f 'mode=%Sp owner=%Su group=%Sg' /tmp/payroll.csv; rm -f /tmp/payroll.csv 2>&1 | head -1

# The mandatory layer, which is per application rather than per user
sudo ls -l /Library/Application\ Support/com.apple.TCC/TCC.db 2>&1 | awk '{print $1, $3, $4, $NF}'
