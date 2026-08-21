# Where the clock comes from, on Windows.
#
# One command per line, same shape as a netlab steps file.
#
# The section this feeds used to say each platform "exposes its state
# differently" and then name no command on two of the three, which told a reader
# nothing they could type. w32tm is the tool, it is the one the exam names, and
# it answers both halves of the question: who this machine is asking, and how
# far off it currently believes it is.

# who this machine synchronises to
w32tm /query /source

# and the state of that synchronisation, offset included
w32tm /query /status
