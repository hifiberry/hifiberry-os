# Optimizations

If you don't need a specific service, you can just remove the start file of this service in /etc/init.d
I recommend not to remove it, but just to prefix it with a "no", e.g.

     mv S99squeezelite noS99squeezelite
     
 If you're not using a HiFiBerry DSP board (DAC+ DSP, Beocreate 4 channel amplifier), you can also disable the
 start of the DSP toolkit
 
     mv S90sigmatcp noS90sigmatcp
