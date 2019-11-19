# Troubleshooting tips

## No metadata from Logitech Media Server

Check, if the command line interface of LMS is enabled and running on port 9090:

`
telnet ip-of-your-lms 9090
`

You can change this setting is LMS "Settings" dialog (Advanced -> Command Line Interface). If this is active, but you still can't connect to port 9090, restart the server. 
