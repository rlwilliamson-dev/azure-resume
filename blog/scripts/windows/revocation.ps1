# How Windows checks whether a certificate has been withdrawn.
#
# One command per line, same shape as a netlab steps file.
#
# The difference worth capturing is that Windows does this inside the operating
# system rather than inside a library. The chain engine fetches, caches and
# evaluates revocation on behalf of every application, so an application does not
# implement it and cannot easily opt out of it.

# Fetch the certificate this site serves, so the checks below have something real
$t = [Net.Sockets.TcpClient]::new('rlwilliamson.dev', 443); $s = [Net.Security.SslStream]::new($t.GetStream()); $s.AuthenticateAsClient('rlwilliamson.dev'); $c = [Security.Cryptography.X509Certificates.X509Certificate2]::new($s.RemoteCertificate); [IO.File]::WriteAllBytes("$env:TEMP\leaf.cer", $c.RawData); $c.Subject

# Build and verify the chain, fetching revocation information over the network
certutil -verify -urlfetch "$env:TEMP\leaf.cer" 2>&1 | Select-String -Pattern "Revocation check|CRL|OCSP|Cert is|Verified Issuance|Leaf certificate revocation check" | Select-Object -First 8

# What the chain engine has already cached, which is where the freshness lives
certutil -urlcache CRL 2>&1 | Select-Object -First 6

# The same question through .NET, which is what an application actually calls
$ch = [Security.Cryptography.X509Certificates.X509Chain]::new(); $ch.ChainPolicy.RevocationMode = 'Online'; $ch.ChainPolicy.RevocationFlag = 'EntireChain'; "chain builds: $($ch.Build($c))"; $ch.ChainStatus | ForEach-Object { $_.Status }
