# Whether a deny list written against filenames can be trusted on this platform.
#
# One command per line, same shape as a netlab steps file.
#
# A directory traversal defence usually inspects the requested path before
# anything opens it, so what matters is how many spellings reach one file. Linux
# resolves dots and symlinks and is otherwise literal about bytes. Windows has
# several naming rules of its own, and each one is a spelling a string check
# will not recognise.

# What the operating system does with dots in a path, before any file is opened
[System.IO.Path]::GetFullPath('C:\inetpub\wwwroot\..\..\Windows\win.ini')

# Whether a forward slash separates here too, since a check written for URLs may only look for one of them
[System.IO.Path]::GetFullPath('C:/inetpub/wwwroot/../../Windows/win.ini')

# Set up one file with known contents to ask the rest of the questions against
$p = Join-Path $env:TEMP 'pathrules'; New-Item -ItemType Directory -Force -Path $p > $null; Set-Content -Path (Join-Path $p 'secret.txt') -Value 'contents' -NoNewline; $p

# Which spellings of that one filename the operating system accepts as the same file
foreach ($n in 'secret.txt', 'SECRET.TXT', 'secret.txt.', 'secret.txt ', 'secret.txt::$DATA') { $v = 'refused'; try { $v = Get-Content -LiteralPath (Join-Path $p $n) -ErrorAction Stop } catch { }; '{0,-22} {1}' -f $n, $v }

# Whether the file has a second, shorter name nobody asked for
cmd /c dir /x $p 2>&1 | Select-String 'secret'
