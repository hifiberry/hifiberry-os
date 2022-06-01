# ALSA equalizer

In previous HiFiBerryOS releases, it was possible to use a graphic equalizer with HiFiBerry sound cards that did not have DSP capabilities. 
This feature was removed with first release in 2021. 

You might think we did this to just sell more hardware. Not really. As we're not making any money with HiFiBerryOS and the development 
costs are quite significant, we need to sell hardware to finance this. However, that was not the main reason for this decision. There are two more important 
points that lead to this decision:

1. Compatibility: Some backends do not work well or do not work at all with ALSAeq, e.g. Spotify.
2. Sound quality: Depending on sample rates and sample format, sound quality of the processed audio can be quite poor - probably due to internal conversions. 
That's not what we want to have in HiFiBerryOS

However, we did not remove the code. The functionality is still integrated. We simply don't recommend users to use it. 

If you still want to experiment with it, you can enable it in the frontend as follows:

* Login via SSH
* touch /etc/hifiberry/alsa-eq.feature
* /opt/hifiberry/bin/reconfigure-players

Do not send any bug reports if you have this enabled! Also note that it might simply stop working in a future release. There will be no work on this anymore and we will simply remove it if there are any problems with it.
