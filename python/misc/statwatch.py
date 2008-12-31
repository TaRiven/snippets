#!/usr/bin/env python2.3
"""

Copyright (c) 2003  Dustin Sallings <dustin@spy.net>
$Id: statwatch.py,v 1.4 2003/07/17 16:37:44 dustin Exp $
"""

import sys
import time
import string
import urllib
import traceback

# Check for threading support and enable a multi-threaded update
try:
    import threading

    class UpdateThread(threading.Thread):
        """Thread that updates a host."""

        def __init__(self, host, prefix=""):
            """Initialize the thread"""
            # Super init
            threading.Thread.__init__(self)

            self.host=host
            self.prefix=""

            self.setDaemon(True)
            self.start()

        def run(self):
            """Perform the update"""
            self.host.update(self.prefix)

    # Remember that we have threading support
    HAS_THREADING=True

except ImportError:
    # No thread support
    HAS_THREADING=False

class Host:
    """A host to watch"""

    def __init__(self, url):
        self.url=url
        self.vals={}

    def update(self, prefix=""):
        """Update this host with values from the given URL"""
        u=urllib.URLopener()
        r=u.open(self.url)
        h={}
        for l in r.readlines():
            l=l.rstrip()
            (k, v) = l.split(' = ')
            if(k.startswith(prefix)):
                v=int(v)
                h[k] = v
        self.vals=h

    def __repr__(self):
        return "<Host: " + self.url + ">"

    # Alias str() to ``
    __str__ = __repr__

def signed(x):
    rv=""
    if rv < 0:
        rv = "-" + `x`
    else:
        rv = "+" + `x`
    return rv

def mergeDicts(dicts):
    """Merge a list of dictionaries into one dictionary with the sum of the
    values of all of the dictionaries."""
    rv={}
    for h in dicts:
        for k,v in h.iteritems():
            ov=rv.get(k, 0)
            rv[k]=(v + ov)
    return rv

if HAS_THREADING:
    def doUpdate(hosts, prefix=""):
        """Have all the host objects update themselves"""
        threads=[]
        for host in hosts:
            try:
                threads.append(UpdateThread(host, prefix))
            except IOError:
                print "***  Error on " + str(host) + ":"
                print "***   " + traceback.format_exception_only(\
                    sys.exc_type, sys.exc_value)[0]

        # Wait for all of the threads to finish
        for t in threads:
            t.join()
else:
    sys.stderr.write("\n!!!Warning:  no thread support!\n\n")
    def doUpdate(hosts, prefix=""):
        """Have all the host objects update themselves"""
        for host in hosts:
            try:
                host.update(prefix)
            except IOError:
                print "***  Error on " + str(host) + ":"
                print "***   " + traceback.format_exception_only(\
                    sys.exc_type, sys.exc_value)[0]

def updateAll(hosts, oldvals, prefix=""):
    """Update all of the hosts into the given dict.  Return the deltas"""
    doUpdate(hosts, prefix)
    dicts=[]
    for host in hosts:
        dicts.append(host.vals)
    # Merge all the dicts
    tmp=mergeDicts(dicts)

    # Now that we've got all the individuals, add them all up and calculate
    # deltas
    deltas={}
    ks=tmp.keys()
    ks.sort()
    for k in ks:
        v=tmp[k]
        ov=oldvals.get(k, 0)
        if v != ov:
            d=(v-ov)
            deltas[k]=d
            # Display the current value
            print k + ":  " + `v` + " (" + signed(d) + ")"
        oldvals[k]=v
    return deltas

def showTimes(times, readings):
    for timeset in times:
        try:
            label=timeset[0]
            timing=float(readings[timeset[1]])
            transcount=0.0
            for k in readings.keys():
                if k.startswith(timeset[2]):
                    transcount = transcount + float(readings[k])
            if transcount > 0 and timing > 0:
                rate=((timing / transcount)/1000)
                print "%s: %.2fs/t" % (label, rate)
        except KeyError:
            # No data found for this key
            pass

if __name__ == '__main__':

    # Build the list of servers
    servers={}

    u=urllib.URLopener()
    r=u.open("http://buildmaster.eng.2wire.com/clusterinfo/clusters.txt")
    for cluster in r.readlines():
        cluster=cluster.strip()
        tmp=[]
        rl=u.open("http://buildmaster.eng.2wire.com/clusterinfo/" + cluster \
            + "-full.txt")
        for s in rl.readlines():
            s=s.strip()
            parts=s.split(".")
            url="http://" + parts[0] + ".diag." + parts[1] \
                + ".2wire.com:8080/admin/monitor/stat"
            tmp.append(url)
        servers[cluster] = tmp

    # Production aliases
    servers['noc0'] = servers['prod']
    # Staging aliases
    try:
        servers['noc1'] = servers['50']
        servers['staging'] = servers['50']
    except KeyError:
        pass
    # Farooq
    servers['noc5']=['http://noc.noc5.2wire.com/admin/monitor/stat']
    # Dustin
    servers['noc13']=\
        ['http://desktop.dsallings.eng.2wire.com/admin/monitor/stat']

    # Time calculation stuff
    timeCalcs=( ('Heartbeat', 'rpc.time.HB', 'rpc.success.CMS_HEARTBEAT'),
                ('Bootstrap' ,'rpc.time.BOOT', 'rpc.success.CMS_BOOTSTRAP'),
                ('Kick', 'rpc.time.KICK' ,'rpc.success.CMS_KICKED'),
            )

    h={}
    hparam=''
    if len(sys.argv) > 1:
        hparam=sys.argv[1]

    # Get the server list
    u=servers.get(hparam, None)
    hosts=None

    # If we didn't get one, print a nice happy error
    if u is None:
        snames=servers.keys()
        snames.sort()
        print ""
        print "The following clusters are available:"
        for s in snames:
            print "\t" + s
        print ""
        raise "Invalid cluster:  " + sys.argv[1]
    else:
        # Construct a host object for each URL
        hosts=map(Host, u)
    print "Using the following URLs:  " + `u`

    # Check to see if a prefix was applied
    prefix=""
    if len(sys.argv) > 2:
        prefix=sys.argv[2]
        print "Limited to this prefix:  " + prefix

    # Loop forever
    while 1:
        print "--------------------------------------- " \
            + time.ctime(time.time())
        deltas=updateAll(hosts, h, prefix)
        print ""
        showTimes(timeCalcs, deltas)
        print ""
        time.sleep(60)
