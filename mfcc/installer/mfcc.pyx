import scipy.io.wavfile
import matplotlib.pyplot  as plt
import sys
import scipy.fftpack
from libc.stdlib cimport malloc,free
from cpython cimport PyObject, Py_INCREF, array


# Numpy must be initialized. When using numpy from C or Cython you must
# _always_ do that, or you will have segfaults
np.import_array()
# Import the Python-level symbols of numpy
import numpy as np
# Import the C-level symbols of numpy
cimport numpy as np


cdef extern from "../c_code/stft.h":
  double* stft(double *wav_data, int samples, int windowSize, int hop_size,\
                 double *magnitude, int sample_freq, int length)

cdef extern from "../c_code/mfcc.h":
  double* mfcc(double *wav_data, int samples, int windowSize, int hop_size,\
               double *magnitude, int sample_freq, int length, int n_mfcc, double *cython_basis)

cpdef play(audData, rate,windowSize,hopSize, mfcc_components):

    #create a memory view, pointer, that can be processed in C
    length = len(audData)
    #the total number of elements to retrieve from the C code is:
    n_elements = int( (length/(windowSize/2))*((windowSize/2)+1) )
    #view for the frequencies
    n_freqs = int(windowSize/2)+1
    cdef double[:] audData_view = audData
    #Create a view for the magnitude
    cdef double[:] magnitude = np.zeros(n_elements)
    #cdef double[:] frequencies = np.zeros(n_freqs)
    print("Total number of freq in Cython %d\n" %(n_freqs))
    print("Analysis with these parameters:")
    print("Total number of samples %d" % n_elements)
    print("Windows length %d" % windowSize)
    print("Hopping size %d" % hopSize)

    #compute the stft
    stft(&audData_view[0], n_elements, windowSize, hopSize,&magnitude[0],rate, length)
    print("Computing MFCC")
    #define an array for mfcc
    cdef int n_mels = 128 #hard coded
    cdef int mel_elements = n_mels* int((windowSize/2)+1)
    cdef double[:] mel_basis = np.zeros(mel_elements)
    #dimensions n_mels * rows ((windowSize/2)+1)
    mfcc(&audData_view[0], n_elements, windowSize, hopSize, &magnitude[0], rate,  length, 20, &mel_basis[0])
    #print first 10 element
    mel_array = np.asarray(mel_basis)
    mel_array = mel_array.reshape([n_mels, int(windowSize/2)+1])
    #TODO: test the dct in scipy vs C
    M = scipy.fftpack.dct(mel_array, axis=0, type=2, norm="ortho")[:mfcc_components]

    return M
