CC  = gcc
LD  = ld

BINUTILS_TARGET  = -DTARGET='"i686-pc-linux-gnu"'
#BINUTILS_TARGET  = -DTARGET='"x86_64-pc-linux-gnu"'
BINUTILS_SOURCE  = ../../binutils-2.18
BINUTILS_LDFLAGS = -L$(BINUTILS_SOURCE)/bfd -L$(BINUTILS_SOURCE)/libiberty -lbfd -liberty 
BINUTILS_CFLAGS  = $(BINUTILS_TARGET) -fPIC -I$(BINUTILS_SOURCE)/bfd -I$(BINUTILS_SOURCE)/include -I$(BINUTILS_SOURCE)/binutils 

# TODO: Change these paths
export PTHREAD_DIR = /home/ras/cs410/glibc-build/nptl
LINKER_DIR = /home/ras/cs410/glibc-build/elf

CTRACED_FILES    = ctraced.c 
CTRACED_OBJ      = $(CTRACED_FILES:%.c=%.o)
CTRACED_CFLAGS   = -rdynamic -g -Wall -pthread -save-temps -finstrument-functions 
CTRACED_LDFLAGS = -rdynamic -lpthread
#CTRACED_LDFLAGS  = -rdynamic -Wl,-dynamic-linker,$(LINKER_DIR)/ld-linux.so.2,-rpath,$(PTHREAD_DIR) -lpthread 

LIBTHREADTRACE_FILES   = libthreadtrace.c addr2line.c 
LIBTHREADTRACE_OBJ     = $(LIBTHREADTRACE_FILES:%.c=%.o)
LIBTHREADTRACE_CFLAGS  = -g -Wall -fPIC -I. $(BINUTILS_CFLAGS) -save-temps 
LIBTHREADTRACE_LDFLAGS = -shared $(BINUTILS_LDFLAGS) -lc --version-script=libthreadtrace.exp 

all: pthreadDriver libthreadtrace.so pc #ctraced  

pthreadDriver: pthreadDriver.o 
	$(CC) -o $@ $+ $(CTRACED_LDFLAGS)
	objdump --source $@ > $@.ss

pthreadDriver.o: pthreadDriver.c Makefile
	$(CC) $(CTRACED_CFLAGS) -c $< -o $@

pc: pc.o
	$(CC) -o $@ $+ $(CTRACED_LDFLAGS)

pc.o: pc.c Makefile
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
