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

## roomeq-range

