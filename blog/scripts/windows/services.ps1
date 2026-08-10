# The services file, which Windows ships in a place nobody guesses.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 10 reads /etc/services to show that a machine carries its own copy of
# the port registry. Windows carries the same file. The path is the difference
# and it is the sort of thing that is obvious once and impossible to recall.

# Same file, same format, different place
Get-Content "$env:SystemRoot\System32\drivers\etc\services" | Select-String "^(ssh|domain|http|https|submission|ldap)\s"
