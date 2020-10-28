# Using HiFiBerryOS in a multiroom environment

## Airplay

Originally, Airplay wasn't designed for multiroom applications. Apple now used Airplay 2 
(there are no open source implementations of this!) for multiroom audio.
However, even the "normal" Airplay can be used to stream to multiple endpoints. The bad news:
this doesn't work from your iPhone or iPad, but only from iTunes.  

## LMS / squeezelite

This is the defacto open source standard for multiroom audio. Logitech media server was designed
for multiroom audio from the beginning. If you're ok that the user interface looks a bit old-fashioned
and the configuration (especially with plugins) can be a bit challenging, have a look at this.

## Snapcast

Snapcast is an open-source multiroom client-server audio player, where all clients are time synchronized with the server 
to play perfectly synced audio. It's not a standalone player, but an extension that turns your existing audio player 
into a Sonos-like multiroom solution. You can find the official repository at 
[github.com/badaix/snapcast](https://github.com/badaix/snapcast).

## Roon

This is the "luxury" multiroom solutions. While Roon, isn't cheap, the sound quality is great and
it has very powerful multiroom capabilities. From the Roon client on the mobile phone (or on your PC), 
you  can easily hand an audio session over from one room to another. You can also group multiple 
endpoints to stream the same audio synchronized to multiple endpoints.

