#!/usr/bin/ruby
#

require 'socket'

PORTP = '1210'		# predict:server port
PORTR = '4533'		# rigctld:port
HOST  = 'localhost'

# 
def calc_doppler(freq, doppler)

  shift_freq = doppler.to_f * freq / 100000.0
  val = shift_freq / 1000.0

  return val

end

#
def get_spec(name)

  sat_nam = ""

  f = open("Doppler.SQF", "r")

  while f.gets
    raw = $_.split(",")
    if raw[0] !~ /;/		        # skip comment 
      k2tmp = raw[1].to_i + raw[2].to_i
      if raw[3] == "USB"	        # find linear transponder
        if raw[0] == name               # find target satellite
          sat_nam = raw[0]
          k2 = k2tmp.to_f / 1000.0      # calc up_freq+down_freq
          break
        end
      end
    end
  end

  f.close

  return sat_nam, k2

end


# -*-*- MAIN PART -*-*-

if ARGV[0] == nil
  STDOUT.printf("Usage: dtune.rb Satellite\n")
  exit
end

sat_nam, k2 = get_spec(ARGV[0])

if sat_nam == "" 
  print  "Satellite \"", ARGV[0], "\" was NOT FOUND!\n"
  exit
end

OFFSET = -0.0040

# --- READ DOWN FREQ.

rig = TCPSocket.open(HOST,PORTR)

rig.printf("V Sub\n")
res = rig.gets

rig.printf("f\n")
res = rig.gets

down = res.to_f / 1000000

# --- CONNECT PREDICT SERVER

udp = UDPSocket.open
udp.bind(HOST, 0)

cmd = sprintf("GET_DOPPLER %s", sat_nam)
print cmd, "\n"
udp.send(cmd, 0, HOST, PORTP)

begin
  doppler = udp.recv(100, 0)
rescue
  printf("NO REPLY from PREDICT server\n")
  exit
end
udp.close

printf("doppler=%f\n", doppler)

# --- CALC UP/DOWN FREQ

sat_down = down - calc_doppler(down, doppler)

printf("RIG down=%f\t", down)
printf("SAT down=%f\n", sat_down)

sat_up  = k2 - sat_down
sat_up += OFFSET.to_f

up = sat_up - calc_doppler(sat_up, doppler)

printf("RIG up  =%f\t", up)
printf("SAT up  =%f\n", sat_up)

# --- SET UP FREQ.

rig.printf("V Main\n")
res = rig.gets
rig.printf("F %9.0f\n", up * 1000000)
res = rig.gets

rig.close()
