# dtune
Tuning assistance for Satelliter.

dtune read a downlink frequency from RIG, Calculate Doppler shift, Set an uplink frequency to RIG.

```
% ruby dtune.rb XW-2F
Calibr_freq = -0.001199
doppler=-0.001929
RIG down=145.981130	SAT down=145.983946
RIG up  =435.353253	SAT up  =435.344855
. 
```
All you need is to adjust TX dail so that you can hear your own signal.

Commands:
```
(line feed) - Update uplink freq. for current downlink freq.
u - Update calibration frequency, Write log file, Keep this offset during session.
m - Toggle CW and LSB.
q - Quit
```

Use predict, rigctld(hamlib 4.2) and Doppler.sqf(SatPC32). Tested on IC-9700.
