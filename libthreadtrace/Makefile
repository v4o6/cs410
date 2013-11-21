CC  = gcc

BINUTILS_TARGET  = '"x86_64-unknown-linux-gnu"'
BINUTILS_SOURCE  = ../binutils-2.22
LIBTRACE_CFLAGS  = -DTARGET=$(BINUTILS_TARGET) -fPIC -I$(BINUTILS_SOURCE)/bfd -I$(BINUTILS_SOURCE)/include -I$(BINUTILS_SOURCE)/binutils -I. -Wall -O4
LIBTRACE_LDFLAGS = -L$(BINUTILS_SOURCE)/bfd -L$(BINUTILS_SOURCE)/libiberty -lbfd -liberty -lz

TARGET		= producer_consumer
TARGET_SRC	= $(TARGET).c 
TARGET_OBJ      = $(TARGET_SRC:%.c=%.o)
CFLAGS		= -rdynamic -g -Wall -pthread
LDFLAGS		= -rdynamic -lpthread


all: $(TARGET) libpthread_wrapper.so

$(TARGET): $(TARGET_OBJ)
	$(CC) -o $@ $+ $(LDFLAGS)

$(TARGET_OBJ): $(TARGET_SRC) Makefile
	$(CC) $(CFLAGS) -c $< -o $@

libpthread_wrapper.so: libpthread_wrapper.o trace.o
	ld -shared -o libpthread_wrapper.so libpthread_wrapper.o trace.o $(LIBTRACE_LDFLAGS) -ldl -lrt

trace.o: trace.c libtrace.h Makefile
	$(CC) -c $< -o $@ $(LIBTRACE_CFLAGS)

libpthread_wrapper.o: libpthread_wrapper.c
	gcc -Wall -fPIC -DPIC -c libpthread_wrapper.c

.IGNORE: clean 
clean:
	@rm -r $(TARGET) libpthread_wrapper.so *.o 2> /dev/null

