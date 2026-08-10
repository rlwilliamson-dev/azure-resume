# How macOS writes a subnet mask.
#
# One command per line, same shape as a netlab steps file.
#
# The third answer to the same question and the least expected one. A prefix
# length is /24, a Windows mask is 255.255.255.0, and BSD prints hexadecimal.

# The mask, in the notation BSD chose
ifconfig en0 | grep -E "inet "

# The same fact asked for directly, which comes back in dotted decimal
ipconfig getoption en0 subnet_mask
