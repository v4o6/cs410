#
#
#

CXX = g++
CC  = gcc
LD  = ld

BINUTILS_TARGET  = -DTARGET='"i686-pc-linux-gnu"'
#BINUTILS_TARGET  = -DTARGET='"x86_64-pc-linux-gnu"'
BINUTILS_SOURCE  = ../../binutils-2.18
BINUTILS_LDFLAGS = -L$(BINUTILS_SOURCE)/bfd -L$(BINUTILS_SOURCE)/libiberty -lbfd -liberty 
BINUTILS_CFLAGS  = $(BINUTILS_TARGET) -I$(BINUTILS_SOURCE)/bfd -I$(BINUTILS_SOURCE)/include -I$(BINUTILS_SOURCE)/binutils 

CTRACED_FILES    = ctraced.c 
CTRACED_OBJ      = $(CTRACED_FILES:%.c=%.o)
CTRACED_CFLAGS   = -rdynamic -g -finstrument-functions -Wall -pthread -save-temps 
CTRACED_LDFLAGS  = -rdynamic -L. -lpthread

LIBTHREADTRACE_FILES   = libthreadtrace.c addr2line.c 
LIBTHREADTRACE_OBJ     = $(LIBTHREADTRACE_FILES:%.c=%.o)
LIBTHREADTRACE_CFLAGS  = -g -Wall -fPIC -I. $(BINUTILS_CFLAGS) -save-temps 
LIBTHREADTRACE_LDFLAGS = -shared $(BINUTILS_LDFLAGS) -ldl -lc --version-script=libthreadtrace.exp 

all: pthreadDriver ctraced libthreadtrace.so 

pthreadDriver: pthreadDriver.o 
	$(CC) -o $@ $+ $(CTRACED_LDFLAGS)
	objdump --source $@ > $@.ss

pthreadDriver.o: pthreadDriver.c Makefile
	$(CC) $(CTRACED_CFLAGS) -c $< -o $@

ctraced: $(CTRACED_OBJ)
	$(CC) -o $@ $+ $(CTRACED_LDFLAGS)
	objdump --source $@ > $@.ss

ctraced.o: ctraced.c $(CTRACED_HEADERS) Makefile
	$(CC) $(CTRACED_CFLAGS) -c $< -o $@

libthreadtrace.o: libthreadtrace.c $(CTRACED_HEADERS) Makefile
	$(CC) $(TRACED_CFLAGS) -c $< -o $@

libthreadtrace.so: $(LIBTHREADTRACE_OBJ)
	$(LD) -o $@ $+ $(LIBTHREADTRACE_LDFLAGS)
	objdump --source $@ > $@.ss

%.o: %.c $(LIBTHREADTRACE_HEADERS) Makefile
	$(CC) $(LIBTHREADTRACE_CFLAGS) -c $< -o $@


.IGNORE: clean 
clean:
	@rm -r pthreadDriver ctraced libthreadtrace.so libpthread.so.0 *.o
	@rm *.s *.ss *.i
