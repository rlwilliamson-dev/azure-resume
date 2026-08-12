# The cumulative interface counters Windows keeps, read twice.
#
# One command per line, same shape as a netlab steps file.
#
# Topic 40 polls an octet counter over SNMP and takes the difference. Windows
# keeps the same counters and exposes them two ways: a cmdlet that reads them
# once, and the performance counter subsystem that samples them on an interval,
# which is the closer analogue to what a poller does.

# Cumulative since the adapter came up
Get-NetAdapterStatistics | Format-Table Name, ReceivedBytes, SentBytes -AutoSize

# Two seconds later. The difference is the only number that means anything
Start-Sleep -Seconds 2

Get-NetAdapterStatistics | Format-Table Name, ReceivedBytes, SentBytes -AutoSize

# The same values as a rate, sampled rather than differenced by hand
Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples | Select-Object -First 2 InstanceName, CookedValue | Format-Table -AutoSize
