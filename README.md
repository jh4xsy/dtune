# dtune
Tuning assistance for Satelliter.

dtune read a downlink frequency from RIG, Calculate Doppler shift, Set an uplink frequency to RIG.

```
% dtune.rb FO-29
Calibr_freq = -0.002300
doppler=-1688.753957
RIG down=435.820000	SAT down=435.827360
RIG up  =145.974805	SAT up  =145.972340
. 
```
All you need is to adjust TX dail so that you can hear your own signal.

Commands:
```
(line feed) - Update uplink freq. for current downlink freq.
u - Update calibration frequency, keep this offset during session.
```

Use predict, rigctld(hamlib) and Doppler.sqf(SatPC32). Tested on IC-910D.
