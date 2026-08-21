# Marking traffic on a Windows host.
#
# One command per line, same shape as a netlab steps file.
#
# The lab in this topic marks packets with ping -Q, which is a way of proving
# the field exists rather than a way anybody marks traffic in an office. On
# Windows the real mechanism is a quality of service policy, normally pushed by
# Group Policy and equally creatable on one machine. It matches traffic and
# writes a DSCP value into every packet the machine sends.

# mark traffic to the usual SIP port with DSCP 46, which is EF
New-NetQosPolicy -Name "Voice" -IPProtocolMatchCondition UDP -IPDstPortStartMatchCondition 5060 -IPDstPortEndMatchCondition 5060 -DSCPAction 46 -Confirm:$false

# read the policy back, which is what a support call needs
Get-NetQosPolicy | Format-List Name, IPProtocol, IPDstPortStart, IPDstPortEnd, DSCPValue

# and remove it, because a capture should not leave a machine configured
Remove-NetQosPolicy -Name "Voice" -Confirm:$false
