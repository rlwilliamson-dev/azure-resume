# Where a Mac can put a key so the operating system cannot hand it over.
#
# One command per line, same shape as a netlab steps file.
#
# The question this answers is not whether the machine is encrypted. It is where
# the key lives, because a key in a file on the same disk is protected by nothing
# once somebody has the disk.

# Whether full-disk encryption is on, which is the visible half
fdesetup status

# What this machine is, since the answer to the next question depends on it
sysctl -n machdep.cpu.brand_string hw.model

# Whether there is a secure enclave, and what the platform says about it
system_profiler SPHardwareDataType 2>/dev/null | grep -iE "chip|model name|activation lock|secure"

# Whether the keychain can hold a key the software never sees
security list-keychains
