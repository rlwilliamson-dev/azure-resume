# What a Windows machine trusts, and what a certificate looks like when it reads one.
#
# One command per line, same shape as a netlab steps file.
#
# Linux keeps its roots in a bundle file and openssl reads them. Windows keeps
# them in a certificate store with a drive letter, which is the difference that
# matters: the trust decision belongs to the operating system rather than to a
# library, so every application inherits it and no application has to be told.

# How many organisations this machine trusts as a root, without anybody choosing
(Get-ChildItem Cert:\LocalMachine\Root).Count

# Four of them, to show what a root actually is and where they come from
Get-ChildItem Cert:\LocalMachine\Root | Sort-Object Subject | Select-Object -First 4 -ExpandProperty Subject

# A root is self-issued, which is the whole definition. Subject and issuer match.
(Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq $_.Issuer }).Count

# The certificate a real server presents, read the way Windows reads it
$t = [Net.Sockets.TcpClient]::new('rlwilliamson.dev', 443); $s = [Net.Security.SslStream]::new($t.GetStream()); $s.AuthenticateAsClient('rlwilliamson.dev'); $c = [Security.Cryptography.X509Certificates.X509Certificate2]::new($s.RemoteCertificate); $c | Format-List Subject, Issuer, NotBefore, NotAfter, SerialNumber
