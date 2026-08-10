# How macOS presents an address and its mask.
#
# One command per line, same shape as a netlab steps file. Lines starting with #
# are printed as narration.
#
# macOS is the third answer to the same question and the least expected one. A
# prefix length is /24 and a Windows mask is 255.255.255.0. BSD prints it in
# hexadecimal, which is correct, unhelpful, and startling the first time.

# The mask, in the notation BSD chose
ifconfig | grep -E "^[a-z0-9]+:|inet |inet6 " | head -14

# The same two facts asked for directly, without the hex
ipconfig getifaddr en0
ipconfig getoption en0 subnet_mask

# The whole of 127.0.0.0/8 answers here too, not only the famous address
ping -c 2 127.9.9.9
