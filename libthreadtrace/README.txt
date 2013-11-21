Wrapper library for libpthreads.
To compile this code you will need the binutils package. It can be obtained from the FSF site. This code has been tested with version 2.22 of the binutils, if using later versions, it might require modifications.

Do unpack the binutils archive, configure it and make it. Do not install it. Then modify the BINUTILS_SOURCE variable in the Makefile to point to the binutils folder.

Now you can compile libpthread_wrapper.so by typing 'make'.  To run the test program and generate a log file, type './run.sh'.

To test an arbitrary pthreads program and generate a log file, modify the program name provided within run.sh.

