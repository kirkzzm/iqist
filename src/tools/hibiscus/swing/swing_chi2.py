#!/usr/bin/env python
""" this module is used to calculate the chi """

from scipy import *
from swing_fast import *
from swing_dump import *

# variables in global namespace, counter
globalc = 0

# calculate the \chi, using eq.(117) and eq.(118)
def swing_cchi(gweigh, vary, gwfix, fixed, sqmc, ifunr, ifuni, iom, intg, om, rfun, rfunc, expand, ders, alphas, gpos, poles):
    """ calculate the chi """

    # define expand_sig
    expand_sig = ones(len(expand), dtype=float)
    expand_sig[2] = 100
    expand_sig[4] = 100
    expand_sig[5] = 100

    # calculate chi2 and chi4, which is very time-consuming, so we try to
    # implement this function by fortran language
    (chi2, chi4, nrm) = fchi(gweigh, vary, gwfix, fixed, sqmc, ifunr, ifuni, ders, expand, expand_sig)

    # calculate chi3
    nrm /= intg
    chi3 = (nrm - 1.0)**2

    # calculate chi5
    # chi5 += Al/((x_i-yl)**2+w_i*Bl)
    chi5 = 0
    for i in range(len(gpos)):
        for l in range(len(poles)):
            chi5 += poles[l][1] / ( ( ( gpos[i] - poles[l][0] ) / poles[l][2] )**4 + gweigh[i] )

    # dump the iteration information periodically
    global_print = 40000
    global globalc
    globalc = globalc + 1
    if ( globalc % global_print == 0 ):
        # current iteration number
        it = globalc / global_print

        # print the chi values
        print '%s %3d' % ('  HIBISCUS >>> iter:', it)
        print '%s %12.8f %s %12.8f' % ('    chi2:', chi2, 'chi3:', alphas[0]*chi3)
        print '%s %12.8f %s %12.8f' % ('    chi4:', alphas[1]*chi4, 'chi5:', chi5)
        print

        # dump the gaussian data to disk file
        swing_dump_gaus(it, gpos, gweigh)

        # dump the self-energy function on real axis to disk file
        swing_dump_sres(it, om, vary, fixed, gweigh, gwfix, rfunc)

        # dump the self-energy function on matsubara axis to disk file
        swing_dump_siom(it, iom, vary, fixed, gweigh, gwfix, ifunr, ifuni)

    return chi2 + alphas[0]*chi3 + alphas[1]*chi4 + chi5