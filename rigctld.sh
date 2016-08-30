#!/bin/sh
# IC-910 (CI-V Address:$4C) + RigBlaster Advantage
rigctld -r /dev/ttyUSB0 -s 19200 -m 334 -t 4533 -C rts_state=OFF -C dtr_state=OFF &
