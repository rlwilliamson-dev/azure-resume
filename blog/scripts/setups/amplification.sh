#!/usr/bin/env sh
# Measure how much larger a DNS answer is than the question that produced it.
# These are ordinary queries to public resolvers, which is what resolvers are
# for. Nothing is spoofed, nothing is flooded, and no third party receives
# anything: the point is the ratio between two message sizes.
dnf -q -y install python3 bind-utils >/dev/null 2>&1
cat > /usr/local/bin/answer-ratio <<'SCRIPT'
#!/usr/bin/env python3
import socket
import struct
import sys

RESOLVER = "1.1.1.1"
TYPES = {"A": 1, "TXT": 16, "DNSKEY": 48}


def query(name, rtype):
    qname = b"".join(bytes([len(p)]) + p.encode() for p in name.split(".")) + b"\x00"
    header = struct.pack(">HHHHHH", 0x1234, 0x0100, 1, 0, 0, 1)
    question = qname + struct.pack(">HH", TYPES[rtype], 1)
    opt = b"\x00" + struct.pack(">HHIH", 41, 4096, 0, 0)      # EDNS0, 4096 byte buffer
    packet = header + question + opt
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(5)
    s.sendto(packet, (RESOLVER, 53))
    reply, _ = s.recvfrom(65535)
    s.close()
    return len(packet), len(reply)


print(f"resolver: {RESOLVER}, EDNS0 buffer 4096")
print(f"{'question':<28} {'sent':>5} {'received':>9}  ratio")
for name, rtype in (("example.com", "A"), ("google.com", "TXT"), ("cloudflare.com", "DNSKEY")):
    sent, rcvd = query(name, rtype)
    print(f"{rtype + ' ' + name:<28} {sent:>5} {rcvd:>9}  {rcvd / sent:>5.1f}x")
SCRIPT
chmod +x /usr/local/bin/answer-ratio
