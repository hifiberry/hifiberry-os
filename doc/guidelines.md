# HiFiBerryOS design guideslines

HiFiBerryOS uses lots of components from different sources. As HiFiBerryOS itself not every component will run 
forever without any problems. 

## Basic problems of complex distributed systems

* Software components will fail
* Redundant software components will also fail (hopefully less often)
* Networks will fail
* Redundant networks also will fail (hopefully less often)
* Updates of components will create issues, not always immediately after the update

## Guidelines to deal with this

To provide a stable system, the following design guidelines should help making the system more stable:

### Implement exception handling and logging.

Almost any part can create results that you do not expect. At least catch exceptions and log these. 

### Loose coupling

It might sound nice to have one centralised configuration for all services without redundant information. However, in 
reality, redundancies help to isolate components. If a component changes the way it expects information in a 
configuration file, other components should not be impacted by this.

### Loose network coupling

Creating a new TCP connection when starting a daemon and expecting it to stay connected for the next years 
doesn't make sense - even if it is a connection on the local host. Daemons get restarted all the time and you should 
not expect a connection to stay open forever. 
When dealing with continuous traffic, monitor connection status and re-connect whenever it is required. For 
connections that are used just every few minutes or even hours, it is easier to just start a new connection each time.

### Monitor for potential problems

Watchdogs can help to detect abnormal application states. However, if a part is seriously broken, it might fail again
directly after the restart. Don't try to restart a component as fast as possible as the system might not do anything 
anymore than restarting this component.

### User input can create problems

I'm not talking about well-known things like SQL injection attacks. It it very clear that you need to 
deal with these. However, it's more than this. A string might look perfectly fine, but a specific part might not
be able to deal with a hostname like "ä%😀". Do not expect any component to be able to deal with the full unicode 
character set.
