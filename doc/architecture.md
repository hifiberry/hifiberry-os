# Architecture

The modular architecture of HiFiBerryOS allows to extend it easily.

## Adding a new services

Adding a services requires two steps:

1. Add the player application. This is the parts that handles music playback. It doesn't need to have have a user interface. 
   Most players don't have one.
   Control of the player and metadata reporting needs to use [MPRIS](https://specifications.freedesktop.org/mpris-spec/2.2/)
2. Add the player module to the GUI. The simplest GUI would be just a UI that can only enable/disable the service. 
   You might add more options (e.g. configuration parameters that the user should be able to set)
   

   
   
