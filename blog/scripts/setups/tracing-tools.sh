# perf and bpftrace, for the topic on finding where the time goes.
#
# Neither ships with the podman machine's Fedora CoreOS, and layering packages
# onto that image would change the machine every capture runs against. A Debian
# container has both in its own repositories, and because a container shares the
# host's kernel, profiling from inside one profiles the real thing.
#
# tracefs is what carries the kernel's tracepoint definitions. It is mounted on
# the host and not inherited by the container's mount namespace, so bpftrace
# reports "tracepoint not found" for everything until this line runs. That
# failure looks like a missing kernel feature and is a missing mount.
apt-get -qq update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
  linux-perf bpftrace strace >/dev/null 2>&1
mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true
