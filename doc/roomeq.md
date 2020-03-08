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
   "phase": [  0,   0, 0.1, 0.15, 0.2, 0.25,  0.2, 0.15,  0.1,  0.05,   0.1]
   },
 "curve": "flat",
 "optimizer": "smooth",
 "filtercount": 10,
 "samplerate": 48000,
 "settings":
   {
   "qmax": 10,
   "mindb": -10,
   "maxdb": 3,
   "add_highpass": true
   }
}
```

Depending on the function you are using, not all parameters may be required. You always need to send frequency (f) and decibel (db) values.
The JSON data will just uses as a command line argument to the scripts (see below)  

## roomeq-range

Returns the usuable frequency range. "Usuable" means that the output is at least -10dB of the average value in the range between 200-8000Hz. This makes sure not to try to optimize at frequencies that speaker can't handle.

Result will look like this:
```
{"fmin": 20, "fmax": 20480}
```


### roomeq-optimize

Optimizes frequency response to match the target curve by applying equalizers.

The result will look like this:

```
{
  "samplerate": 48000,
  "f_min": 80,
  "f_max": 20480,
  "error_input": 2.0523979190035857,
  "frequencies_full": [
    20,
    40,
    80,
    160,
    320,
    640,
    1280,
    2560,
    5120,
    10240,
    20480
  ],
  "response_normalized_full": [
    -25.02,
    -15.02,
    -5.02,
    2.38,
    -5.02,
    2.08,
    0.4800000000000001,
    4.58,
    -2.12,
    -1.32,
    -7.02
  ],
  "response_optimize_range": [
    -5.02,
    2.38,
    -5.02,
    2.08,
    0.4800000000000001,
    4.58,
    -2.12,
    -1.32
  ],
  "frequencies": [
    80,
    160,
    320,
    640,
    1280,
    2560,
    5120,
    10240
  ],
  "target_curve": [
    -7.4999999999999964,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0
  ],
  "target_weights": [
    [
      1,
      0.5
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ],
    [
      1,
      1
    ]
  ],
  "correction_curve": [
    -9.897985643870312,
    -3.5943769392580585,
    4.0282395594494504,
    -2.3451890631928403,
    -0.10399883187746006,
    -4.097423887314459,
    1.158949800292876,
    1.7362519113401598
  ],
  "correction_angle": [
    
  ],
  "response_corrected": [
    -8.897385730585672,
    0.7237280685098911,
    -0.46532173890818523,
    -0.13067525446896433,
    0.40970691834508327,
    0.4908962879942015,
    -0.959086744647456,
    0.41663097537377136
  ],
  "eqs": [
    {
      "a0": 1,
      "a1": -1.979164950637508,
      "a2": 0.9792734754579923,
      "b0": 0.9896096065238751,
      "b1": -1.9792192130477502,
      "b2": 0.9896096065238751,
      "type": "hp",
      "f0": 80.0,
      "q": 0.5,
      "db": null
    },
    {
      "a0": 1,
      "a1": -1.811353369759114,
      "a2": 0.9180418176956454,
      "b0": 0.9832944696506943,
      "b1": -1.811353369759114,
      "b2": 0.9347473480449511,
      "type": "eq",
      "f0": 2560,
      "q": 4.999999999999999,
      "db": -4.5485766507754315
    },
    {
      "a0": 1,
      "a1": -1.9872078279457714,
      "a2": 0.9873167937865033,
      "b0": 0.99817334443985,
      "b1": -1.9872078279457714,
      "b2": 0.9891434493466532,
      "type": "eq",
      "f0": 80,
      "q": 0.9723036318902865,
      "db": -2.9509269755882244
    },
    {
      "a0": 1,
      "a1": -0.19788015225129915,
      "a2": -0.13343815087978864,
      "b0": 1.1267853517864534,
      "b1": -0.19788015225129915,
      "b2": -0.26022350266624217,
      "type": "eq",
      "f0": 10240,
      "q": 0.33643579295814874,
      "db": 1.7536281379290026
    },
    {
      "a0": 1,
      "a1": -1.99122976689195,
      "a2": 0.9929779471608385,
      "b0": 1.0014484302182394,
      "b1": -1.99122976689195,
      "b2": 0.991529516942599,
      "type": "eq",
      "f0": 320,
      "q": 4.999999999999999,
      "db": 2.9999999999999316
    },
    {
      "a0": 1,
      "a1": -1.9743561549472772,
      "a2": 0.9813048699959958,
      "b0": 0.9980037508983862,
      "b1": -1.9743561549472772,
      "b2": 0.9833011190976094,
      "type": "eq",
      "f0": 640,
      "q": 4.999999999999964,
      "db": -2.086668164877255
    },
    {
      "a0": 1,
      "a1": -1.990912309213979,
      "a2": 0.9926602107740726,
      "b0": 1.0010733564587682,
      "b1": -1.990912309213979,
      "b2": 0.9915868543153045,
      "type": "eq",
      "f0": 320,
      "q": 4.999999999999999,
      "db": 2.22845041124511
    },
    {
      "a0": 1,
      "a1": -1.9650962596041421,
      "a2": 0.9652040129870725,
      "b0": 0.9980547935236838,
      "b1": -1.9650962596041421,
      "b2": 0.9671492194633885,
      "type": "eq",
      "f0": 80,
      "q": 0.3137728334227004,
      "db": -1.029846904118282
    },
    {
      "a0": 1,
      "a1": -1.6494955634868824,
      "a2": 0.6553009368568666,
      "b0": 0.9978116307096956,
      "b1": -1.6494955634868824,
      "b2": 0.6574893061471712,
      "type": "eq",
      "f0": 640,
      "q": 0.20220513139405033,
      "db": -0.11099328071738762
    },
    {
      "a0": 1,
      "a1": -1.921299544544896,
      "a2": 0.9214048963944732,
      "b0": 1.000549207468468,
      "b1": -1.921299544544896,
      "b2": 0.9208556889260052,
      "type": "eq",
      "f0": 80,
      "q": 0.12711603312221625,
      "db": 0.120550219409348
    }
  ],
  "eqdefinitions": [
    "hp:80.0:0.5",
    "eq:2560:4.999999999999999:-4.5485766507754315",
    "eq:80:0.9723036318902865:-2.9509269755882244",
    "eq:10240:0.33643579295814874:1.7536281379290026",
    "eq:320:4.999999999999999:2.9999999999999316",
    "eq:640:4.999999999999964:-2.086668164877255",
    "eq:320:4.999999999999999:2.22845041124511",
    "eq:80:0.3137728334227004:-1.029846904118282",
    "eq:640:0.20220513139405033:-0.11099328071738762",
    "eq:80:0.12711603312221625:0.120550219409348"
  ]
}
```

### Examples

You can run a simple test using the sample file /opt/hifiberry/contrib/frequency-demo.json:
```
/opt/hifiberry/bin/roomeq-range /opt/hifiberry/contrib/frequency-demo.json
/opt/hifiberry/bin/roomeq-optimize /opt/hifiberry/contrib/frequency-demo.json
```
