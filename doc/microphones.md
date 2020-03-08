# Microphones

HiFiBerryOS supports acoustics measurements using a measurement microphone. You should not even try to use a 
"normal" microphone used for music or voice recordings for this. 


## Measurements

The following measurements where taken with an 1kHz test tone and a simple sound level meter to measure the 
sensitivity of the phone. This isn't an exact calibration, but it's good enough for our purpose here. 

### HiFiBerry Mic

|Input level|Sound pressure|Max. pressure|
|---|---|---|
|81.5|-33.7|115.2
|89.1|-26.1|115.2
|97.5|-18.5|116
|76.5|-39.2|115.7

Max pressure at 0dbFS will be **115.5dB**

### MiniDSP UMIK-1 (18dB amplification)

|Input level|Sound pressure|Max. pressure|
|---|---|---|
|82.6|-34|116.6|
|88.6|-26.3|114.9|
|94.4|-20.7|115.1|
|75.7|-39.8|115.5|

Max pressure at 0dbFS will be **115dB**. This corresponds well to data sheet "133dB SPL @ 0dB analog gain setting"

### Dayton UMM-6
|Input level|Sound pressure|Max. pressure|
|---|---|---|
|66.5|-68|134.1|
|80.5|-57|137.5|
|90.3|-49|139.3|
|77.2|-59.5|136.7|

The measurements here are not fully consistent, therefore we'll do a bit guessing and expect **137.5db** at 0dbFS
