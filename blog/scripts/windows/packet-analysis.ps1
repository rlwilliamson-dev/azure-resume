# Reading packets off the wire on Windows, with the tool that ships in the box.
#
# One command per line, same shape as a netlab steps file.
#
# The exam names "protocol analyzer" as a category rather than naming a product.
# Windows has had a packet capture built in since 1809, driven from the command
# line, so a transcript of it belongs next to the tcpdump ones rather than a
# screenshot of something that has to be installed.

# Start clean, in case anything was left behind
pktmon filter remove

# One filter, so the capture holds a conversation rather than everything
pktmon filter add WebTraffic -t TCP -p 443

pktmon filter list

# Capture to a file, small packets only, because the headers are the interesting part
pktmon start --capture --pkt-size 128 --file-name $env:TEMP\np.etl --file-size 8

# Something for it to capture
Invoke-WebRequest -Uri https://1.1.1.1 -UseBasicParsing -TimeoutSec 10 | Out-Null

pktmon stop

# Turn the binary capture into text and read the first few packets of it
pktmon etl2txt $env:TEMP\np.etl --out $env:TEMP\np.txt

Get-Content $env:TEMP\np.txt -TotalCount 14
