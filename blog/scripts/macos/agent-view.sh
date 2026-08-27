# What a network view of a machine can learn, against what something running on
# the machine can learn about the same service.
#
# One command per line, same shape as a netlab steps file.
#
# The Linux column pairs ss with ps. macOS has no ss at all, and the tool that
# answers both halves at once is lsof, which needs privileges to see processes
# it does not own.

# The agentless half: which ports answer
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || NR<=5 {print $1, $2, $3, $9}'

# The agent half: what is actually behind the first of those ports
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $2}' | xargs -I{} ps -o pid,user,etime,comm -p {} 2>/dev/null

# What no network view could have told you: whether the binary is signed
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $2}' | xargs -I{} sh -c 'codesign -dv --verbose=2 /proc/{} 2>/dev/null || ps -o comm= -p {} | xargs -I@ codesign --verify --verbose=2 @ 2>&1 | head -2'

# How many listening sockets there are in total
sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
