#
#
#

CXX = g++
CC  = gcc
LD  = ld

#Some of the flags that affect us
STRESS_FLAGS = #-O2 #-fomit-frame-pointer #-O3 

#BINUTILS_TARGET  = -DTARGET='"i686-pc-linux-gnu"'
BINUTILS_TARGET  = -DTARGET='"x86_64-pc-linux-gnu"'
BINUTILS_SOURCE  = ../binutils-2.23.0
BINUTILS_LDFLAGS = -L$(BINUTILS_SOURCE)/bfd -L$(BINUTILS_SOURCE)/libiberty -lbfd -liberty 
BINUTILS_CFLAGS  = $(BINUTILS_TARGET) -I$(BINUTILS_SOURCE)/bfd -I$(BINUTILS_SOURCE)/include -I$(BINUTILS_SOURCE)/binutils 

CTRACED_HEADERS =  
CTRACED_FILES    = ./ctraced/ctraced.c 
CTRACED_OBJ      = $(CTRACED_FILES:%.c=%.o)
CTRACED_CFLAGS   = -rdynamic -g -finstrument-functions -Wall -pthread -save-temps $(STRESS_FLAGS) 
CTRACED_LDFLAGS  = -rdynamic -L. -lpthread

CPPTRACED_HEADERS =  
CPPTRACED_FILES   = ./cpptraced/cpptraced.cpp 
CPPTRACED_OBJ     = $(CPPTRACED_FILES:%.cpp=%.o)
CPPTRACED_CFLAGS  = -rdynamic -g -finstrument-functions -Wall -pthread -save-temps $(STRESS_FLAGS) 
CPPTRACED_LDFLAGS = -rdynamic -L. -lpthread

LIBTHREADTRACE_HEADERS =  
LIBTHREADTRACE_FILES   = libthreadtrace.c addr2line.c 
LIBTHREADTRACE_OBJ     = $(LIBTHREADTRACE_FILES:%.c=%.o)
LIBTHREADTRACE_CFLAGS  = -g -Wall -fPIC -I. $(BINUTILS_CFLAGS) -save-temps $(STRESS_FLAGS) 
LIBTHREADTRACE_LDFLAGS = -shared $(BINUTILS_LDFLAGS) -ldl -lc --version-script=libthreadtrace.exp 



all: ctraced cpptraced addr2line libthreadtrace.so 

addr2line: addr2line.c Makefile 
	$(CC) -DMAIN_FUNC -o $@ $< $(BINUTILS_CFLAGS) $(BINUTILS_LDFLAGS) 
	#./$@ cpptraced 0x8048fa6 0x8048fa6  

ctraced: $(CTRACED_OBJ)
	$(CC) -o $@ $+ $(CTRACED_LDFLAGS)
	objdump --source $@ > $@.ss

cpptraced: $(CPPTRACED_OBJ)
	$(CXX) -o $@ $+ $(CPPTRACED_LDFLAGS)
	objdump --source $@ > $@.ss

cpptraced.o: cpptraced.cpp $(CPPTRACED_HEADERS) Makefile
	$(CXX) $(CPPTRACED_CFLAGS) -c $< -o $@

ctraced.o: ctraced.c $(CTRACED_HEADERS) Makefile
	$(CC) $(CTRACED_CFLAGS) -c $< -o $@

libthreadtrace.o: libthreadtrace.c $(CTRACED_HEADERS) Makefile
	$(CC) $(TRACED_CFLAGS) -c $< -o $@

libthreadtrace.so: $(LIBTHREADTRACE_OBJ)
	$(LD) -o $@ $+ $(LIBTHREADTRACE_LDFLAGS)
	objdump --source $@ > $@.ss

%.o: %.c $(LIBTHREADTRACE_HEADERS) Makefile
	$(CC) $(LIBTHREADTRACE_CFLAGS) -c $< -o $@


.IGNORE: clean realclean
clean:
	rm -r ctraced cpptraced libthreadtrace.so addr2line *.o core*

realclean: clean
	rm -r *.s *.ss *.ii *.i 


testc: all 
	#LD_PRELOAD=./libthreadtrace.so ./ctraced/ctraced
	./ctrace.sh ./ctraced/ctraced

testcpp: all 
	#LD_PRELOAD=./libthreadtrace.so ./cpptraced/cpptraced
	./ctrace.sh ./cpptraced/cpptraced

.IGNORE: backup 
backup: clean
	#rm -rf /media/disk/ctrace/*
	cd .. && cp -pR ctrace /media/disk/
	sync
	ls -l /media/disk/ctrace/*

refresh: 
	cp -pR /media/disk/ctrace/* . 
