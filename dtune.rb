#!/usr/bin/ruby
#
# dtune.rb by JH4XSY/1 2024
#

require 'socket'
require 'date'

# Constants
PORTP = '1210'          # predict:server port
PORTR = '4533'          # rigctld:port
HOST  = 'localhost'
DEFAULT_MODE = "CW"     # CW is default!, because I love CW!!

# Calculate Doppler shift
def calc_doppler(freq, doppler)

  shift_freq = doppler.to_f * freq / 100000.0
  val = shift_freq / 1000.0

  return val

end

# Read satellite specification from Doppler.SQF
def get_spec(name)

  sat_nam = ""
  k2 = 0
  down = 0

  f = open("Doppler.SQF", "r")

  while f.gets
    raw = $_.split(",")
    if raw[0] !~ /;/                    # skip comment 
      k2tmp = raw[1].to_i + raw[2].to_i
      if raw[3] == "USB"                # search linear transponder
        if raw[0] == name               # search target satellite
          sat_nam = raw[0]
          k2 = k2tmp.to_f / 1000.0      # calc up_freq+down_freq
          down = raw[1].to_i            # get downlink freq
          break
        end
      end
    end
  end

  f.close

  return sat_nam, k2, down

end

# Get calibration FREQ. of the sat:$name from Calibr.dat
def get_calibr_freq(name)

  f = open("Calibr.dat", "r")

  calibr_freq = 0

  while f.gets
    raw = $_.split(",")
    if raw[0] !~ /;/                    # skip comment 
      if raw[0] == name                	# search target satellite
        tmp = raw[1].to_f
        calibr_freq = tmp / 1000.0      # convert to MHz 
        break
      end
    end
  end

  return calibr_freq

end

# Sets up the RIG with provided settings
def setup_rig(rig, down_freq)

  rig.puts("S 0 Sub\n")
  rig.gets

  rig.puts("V Main\n")
  rig.gets
  rig.puts("F #{down_freq * 1000}\n")
  rig.gets
  sleep 0.3  # wait for VFO selection
  rig.puts("M USB 3000\n")
  rig.gets
  rig.puts("V Sub\n")
  rig.gets
  rig.puts("M CW 0\n")
  rig.gets
  rig.puts("L AF 0\n")
  rig.gets

end


# -*-*- MAIN PART -*-*-

if ARGV.empty?
  STDOUT.printf("Usage: dtune.rb Satellite\n")
  exit
end

sat_nam, k2, down = get_spec(ARGV[0])

if sat_nam.empty?
  printf("Satellite %s was NOT FOUND!\n", ARGV[0])
  exit
end

down_old = down/1000

calibr_freq = get_calibr_freq(ARGV[0])
printf("Calibr_freq = %f\n", calibr_freq)

# --- setup RIG

rig = TCPSocket.open(HOST, PORTR)
setup_rig(rig, down)
mode = DEFAULT_MODE

while 1

  # --- READ DOWN FREQ.

  rig.printf("V Main\n")
  res = rig.gets
  sleep 0.1                   # wait VFO SELECTION

  rig.printf("f\n")
  res = rig.gets
  
  down = res.to_f / 1000000

  # --- CHECK DOWN FREQ.
  if ( down.to_i != down_old.to_i)
     print "*"
     down = down_old          # discard MAIN VFO FREQ
  end

  # --- CONNECT PREDICT SERVER

  udp = UDPSocket.open
  udp.bind(HOST, 0)

  cmd = sprintf("GET_DOPPLER %s", sat_nam)
  udp.send(cmd, 0, HOST, PORTP)

  begin
    doppler = udp.recv(100, 0)
  rescue
    printf("NO REPLY from PREDICT server\n")
    exit
  end

  printf("doppler=%f\n", doppler.to_f/10**6)

  cmd = sprintf("GET_TLE %s", sat_nam)
  udp.send(cmd, 0, HOST, PORTP)

  res = udp.recv(100, 0)
  unless res.include?(sat_nam)
    printf("NO TLE in PREDICT servere\n")
    break
  end

  udp.close

  # --- CALC UP/DOWN FREQ

  sat_down = down - calc_doppler(down, doppler)

  printf("RIG down=%f\t", down)
  printf("SAT down=%f\n", sat_down)

  sat_up  = k2 - sat_down
  sat_up += calibr_freq

  up = sat_up - calc_doppler(sat_up, doppler)

  printf("RIG up  =%f\t", up)
  printf("SAT up  =%f\n", sat_up)

  # --- SET UP FREQ.

  rig.printf("V Sub\n")
  res = rig.gets
  rig.printf("F %9.0f\n", up * 1000000)
  res = rig.gets

  # --- WAIT KEY-INPUT

  rig.printf("V Main\n")
  res = rig.gets()

  printf(". ")
  cmd = STDIN.gets.chop

  if cmd == "u" then           # U)pdate calibr_freq
    rig.printf("V Sub\n")
    res = rig.gets
    rig.printf("f\n")
    res = rig.gets

    up2 = res.to_f / 1000000

    calibr_freq += up2 - up
    printf("Calibr_freq = %f\n", calibr_freq)

    f = open("Calibr.csv", "a") # record in file
    f.printf("%s,%f,%s\n", sat_nam, calibr_freq, Time.now.utc)
    f.close

  end

  if cmd == "m" then           # M)ode change on TX VFO
    rig.printf("V Sub\n")
    res = rig.gets

    mode = (mode == "CW") ? "SSB" : "CW"
    puts "mode: #{mode}"
    rig.puts("M #{(mode == "CW") ? "CW" : "LSB"} 0\n")
    rig.gets
  end

  if cmd == "q" then          # Q)uit
    break
  end  

  down_old = down             # KEEP DOWN FREQ 

end

# --- setup RIG

rig.printf("S 0 VFOA\n")
res = rig.gets()

rig.close()
