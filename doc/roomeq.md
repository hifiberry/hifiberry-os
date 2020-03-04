# Room equalisation tools

Room equalisation filter calculation is handled by a HiFiBerry web service. There are command line tools to use it

## roomeq-preset

`roomeq-preset --curves` displays target curves supported by the optimizer:

```
{
 "room_only": [[20, 0, [1, 0.5]], [250, 0]], 
 "falling_slope": [[20, 0, [1, 0.3]], [100, 0, [1, 0.6]], [200, 0, [0.9, 0.7]], [500, 0, [0.9, 0.5]], [1000, 0, [0.5, 0.3]], [10000, -3, 0.1], [25000, -6]], 
 "weighted_flat": [[20, 0, [1, 0.3]], [100, 0, [1, 0.6]], [200, 0, [0.9, 0.7]], [500, 0, 0.6], [5000, 0, 0.4], [10000, 0, 0.1], [25000, 0]], 
 "flat": [[20, 0], [25000, 0]]
}
```

Each curve consists of a list of tuples:
frequency, target-decibel, weight for corrections

Weight is a value between 0 and 1. The higher the value the more the optimizer will try to optimize at this frequency. 

The optimizer will only work in the range from the first to the last given frequency, e.g. the "room_only" 
optimizer shown above will not touch the frequency response above 250Hz

## Uploading data to the optimzer

The optimzer tools expect a data in JSON format as follows

```
{
 "measurement": 
   {
   "f":     [ 20,  40,  80,  160, 320,  640, 1280, 2560, 5120, 10240, 20480],
   "db":    [-25, -15,  -5,  2.4,  -5,  2.1,  0.5,  4.6, -2.1,  -1.3,  -7.0],
   "phase": [  0,   0, 0.1, 0.15, 0.2, 0.25,  0.2, 0.15,  0.1,  0.05,   0.1],
   }
  "curve": "flat",
  "optimizer": "smooth",
  "filtercount": 10,
  "samplerate": 48000,
}
```

Depending on the function you are using, not all parameters may be required. You always need to send frequency (f) and decibel (db) values.

## roomeq-range

Returns the usuable frequency range. "Usuable" means that the output is at least -10dB of the average value in the range between 200-8000Hz. This makes sure not to try to optimize at frequencies that speaker can't handle.


