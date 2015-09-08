#!/usr/bin/python
import sys, os
 
def usage():
    print("%s file: lift over rs number. " % sys.argv[0] )
    print("file should look like:")
    print("11111")
    print("11112")
    print("...")
def myopen(fn):
    import gzip
    try:
        h = gzip.open(fn)
        ln = h.read(2) # read arbitrary bytes so check if @param fn is a gzipped file
    except:
        # cannot read in gzip format
        return open(fn)
    h.close()
    return gzip.open(fn)
 
RS_HISTORY = set() # store rs
RS_MERGE = dict() # high_rs -> (lower_rs, current_rs)
if __name__ == '__main__':
    if len(sys.argv) != 2:
        usage()
        sys.exit(1)
 
    # record obsolete rs number
    for ln in myopen('SNPHistory.bcp.gz'):
        fd = ln.strip().split('\t')
        if ln.find('re-activ') < 0:
            RS_HISTORY.add(fd[0])
 
    # record rs number merge history
    for ln in myopen('RsMergeArch.bcp.gz'):
        fd = ln.strip().split('\t')
        h, l = fd[0], fd[1]
        c = fd[6]
        # print 'c=', c
        RS_MERGE[h] = (l, c)
 
    # # find some retracted SNPs for fun
    # for h, v in RS_MERGE.iteritems():
    #   l, c = v
    #   if c in RS_HISTORY:
    #       print h, '->', l

    import re
    rsPattern = re.compile(r'[0-9]*')
    for ln in myopen(sys.argv[1]):
        rs = ln.strip()
        if not rsPattern.match(rs):
            print 'ERROR: rs number should be like "1000"'
            sys.exit(2)
        # rs number not appear in RS_MERGE -> there is no merge on this rs
        if rs not in RS_MERGE:
            print "unchanged\t", rs
            continue
        # lift rs number
        while True:
            if rs in RS_MERGE:
                rsLow, rsCurrent = RS_MERGE[rs]
                if rsCurrent not in RS_HISTORY:
                    print "lifted\t", rsCurrent
                    break
                else:
                    rs = rsLow
            else:
                print "unlifted\t", rs
                break
