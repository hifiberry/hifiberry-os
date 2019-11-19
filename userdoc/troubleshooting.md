# Troubleshooting tips

## No metadata from Logitech Media Server

Have a look at the lmsmpris logs:

`
journalctl -u lmsmpris
`

You might see a message that lmsmpris isn't connected to a server:

`
WARNING: root - LMS socket not connected, ignoring command
`

Check, if the command line interface of LMS is enabled and running on port 9090:

`
telnet ip-of-your-lms 9090
`

You can change this setting is LMS "Settings" dialog (Advanced -> Command Line Interface). If this is active, but you still can't connect to port 9090, restart the server. 
