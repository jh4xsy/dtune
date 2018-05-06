# dtune
Tuning assistance for Satelliter.

Read a downlink frequency from RIG, Calculate Doppler shift, Set an uplink frequency to RIG

Use predict, rigctld(hamlib) and Doppler.sqf(SatPC32).
```
% dtune.rb FO-29
Calibr_freq = -0.002300
doppler=-1688.753957
RIG down=435.820000	SAT down=435.827360
RIG up  =145.974805	SAT up  =145.972340
. 
```
Commands:
```
(line feed) - Update uplink freq. for current downlink freq.
u - Update calibration frequency
```


Tested on IC-910D
