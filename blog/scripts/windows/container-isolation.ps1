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

# Start one container of each kind, both running the same long ping
docker run -d --rm --name proc --isolation=process mcr.microsoft.com/windows/nanoserver:ltsc2025 ping -n 300 127.0.0.1 > $null; docker run -d --rm --name hyp --isolation=hyperv mcr.microsoft.com/windows/nanoserver:ltsc2025 ping -n 300 127.0.0.1 > $null; Start-Sleep -Seconds 8; docker ps --format '{{.Names}}  {{.Status}}'

# How many ping processes the host can see, when each container is running one
'{0} ping process visible to the host' -f @(Get-Process -Name PING -ErrorAction SilentlyContinue).Count

# What the host sees for the container that asked for its own virtual machine
Get-Process -Name vmmem*, vmwp -ErrorAction SilentlyContinue | Select-Object Name, Id | Format-Table -AutoSize

# Remove both containers
docker rm -f proc hyp 2>&1 | Out-Null; 'both removed'
