# Whether a container on this machine shares its kernel, and whether it has to.
#
# One command per line, same shape as a netlab steps file.
#
# Linux containers always share the host kernel. Windows offers two modes: process
# isolation, which shares the kernel the same way, and Hyper-V isolation, which
# gives each container its own small virtual machine. The second needs hardware
# virtualisation, which a hosted runner may not expose.

# Whether a container runtime is installed, and what it reports as its default isolation
docker info --format 'os type: {{.OSType}}   default isolation: {{.Isolation}}   kernel: {{.KernelVersion}}' 2>&1

# The build of Windows this machine runs
cmd /c ver

# The build a container reports, in process isolation, which shares this machine's kernel
docker run --rm --isolation=process mcr.microsoft.com/windows/nanoserver:ltsc2025 cmd /c ver 2>&1 | Select-Object -Last 2

# The same container asked for its own virtual machine instead
docker run --rm --isolation=hyperv mcr.microsoft.com/windows/nanoserver:ltsc2025 cmd /c ver 2>&1 | Select-Object -Last 2
