#!/usr/bin/env python
import numpy as np
from numpy.polynomial import polynomial as P
import sys
import pylab as plt

def usage():
  print """
Usage: offsets_plot.py <offsets> <r_min> <r_max> <az_min> <az_max> <title>
    data    (input) range and azimuth offset data
    r_min   minimum range offset plot scale
    r_max   maximum range offset plot scale
    az_min  minimum azimuth offset plot scale
    az_max  maximum azimuth offset plot scale
    title   plot title
"""
print '*** Analyze offset tracking data v1.0 13-Jan-2014 clw ***'
if len(sys.argv) < 7:
  usage()
  sys.exit(-1)

offs = np.loadtxt(sys.argv[1])
r_min = float(sys.argv[2])
r_max = float(sys.argv[3])
az_min = float(sys.argv[4])
az_max = float(sys.argv[5])

(rows,cols) = offs.shape
print 'number of offset measurments: %d '%(rows)

r0 = offs[0,0]
r1 = offs[rows-1,0]
rp = offs[:,0]    #range pixel at the center of the patch
azp = offs[:,1]
roff = offs[:,2]
azoff = offs[:,3]
snr = offs[:,4]   #last column is SNR value  for the range and azimuth offset

print 'first range sample: %f    last range sample (s): %f'%(r0,r1)
#generate an array of range positions with 10 points
rp2 = np.linspace(0, r1, 100, endpoint=True) 

#linear fit is performed using points starting with data
cr, statsr = P.polyfit(rp[:], roff[:], 1, full=True)
caz, statsaz = P.polyfit(rp[:], azoff[:], 1, full=True)

print 'range offset polynomial coefficients:', cr
print 'range offset polynomial fit stats:', statsr
print 'std. deviation of the range offsets: %.5f'%((statsr[0]/(rows-1))**.5,)
print '\nazimuth offset polynomial coefficients:', caz
print 'azimuth offset polynomial fit stats:', statsaz
print 'std. deviation of the azimuth offsets: %.5f'%((statsaz[0]/(rows-1))**.5,)

fitr = P.polyval(rp2,cr)  #range offset linear fit evaluated 
fitaz = P.polyval(rp2,caz)  #range offset linear fit evaluated 

#plotting with Matplotlib
fig = plt.figure(figsize=(12,10))
ax = fig.add_subplot(3,1,1)
plt.xlim(0,r1)
plt.ylim(r_min, r_max)
plt.grid(True)
plt.title(sys.argv[6])
#plt.text(0.5, 0.95,'Sample offset: %d    Fit at %d seconds: %.3f'%(offset, toff,fit[40]), color='g', horizontalalignment='center',verticalalignment='center',transform = ax.transAxes)
plt.ylabel('Range Offset')
plt.plot(rp, roff, color='blue', linestyle='-', marker='o', markersize=3, mfc='r')
plt.plot(rp2, fitr, color='green',linestyle='-')

plt.subplot(312)
plt.ylabel('Azimiuth Offset')
plt.xlim(0,r1)
plt.ylim(az_min, az_max)
plt.grid(True)
plt.plot(rp, azoff, color='blue', linestyle='-', marker='o', markersize=3, mfc='r')
plt.plot(rp2, fitaz, color='green',linestyle='-')

plt.subplot(313)
plt.xlabel('Range Sample')
plt.ylabel('SNR')
plt.xlim(0,r1)
plt.ylim(0,60)
plt.grid(True)
plt.plot(rp, snr, color='blue', linestyle='-', marker='o', markersize=3, mfc='r')

plt.show()












