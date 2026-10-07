# Whether a container on this machine could share its kernel, and why it cannot.
#
# One command per line, same shape as a netlab steps file.
#
# A Linux container shares the kernel of the machine it runs on, and macOS does
# not have a Linux kernel to share. Every Linux container on a Mac therefore runs
# inside a Linux virtual machine, which is how the capture toolchain for this
# track works, and it means the isolation is virtual-machine strength by accident.

# The kernel this machine runs
uname -sr

# Whether the hypervisor framework is available here, which is what a container runtime would use to start its virtual machine
sysctl -n kern.hv_support 2>&1

# Whether any container runtime is installed on this machine
for c in docker podman colima container; do printf '%-8s %s\n' "$c" "$(command -v $c || echo 'not installed')"; done
