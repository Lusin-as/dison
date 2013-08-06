from TOSSIM import *
from random import *
import sys

t = Tossim([])
r = t.radio()

f = open("topo.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if s[0] == "gain":
      r.add(int(s[1]), int(s[2]), float(s[3]))

noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, 10):
      m = t.getNode(i);
      m.addNoiseTraceReading(val)



for i in range(0, 5):
  m = t.getNode(i);
  m.createNoiseModel();
  time = randint(t.ticksPerSecond(), 10 * t.ticksPerSecond())
  m.bootAtTime(time)
  print "Booting ", i, " at time ", time

print "Starting simulation."

t.addChannel("Election", sys.stdout)
t.addChannel("Management", sys.stdout)
#t.addChannel("Application", sys.stdout)

while (t.time() < 5000 * t.ticksPerSecond()):
  t.runNextEvent()

print "Completed simulation."
