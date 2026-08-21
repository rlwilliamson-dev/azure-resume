# Throwaway probe. Which of these actually answers on macOS 26, and what does
# the system openssl call itself when Homebrew is not in front of it.
which -a openssl
/usr/bin/openssl version
security list-keychains -d system
ls /System/Library/Keychains/
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | grep -c "BEGIN CERT"
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | head -2
security dump-trust-settings -d 2>&1 | head -5
security find-certificate -a -Z /System/Library/Keychains/SystemRootCertificates.keychain 2>&1 | grep -c "SHA-256 hash"
