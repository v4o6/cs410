CC  = gcc

#BINUTILS_TARGET  = '"x86_64-pc-linux-gnu"'
#BINUTILS_TARGET  = '"x86_64-laptop-linux-gnu"'
BINUTILS_TARGET  = '"x86_64-unknown-linux-gnu"'
BINUTILS_SOURCE  = ../binutils-2.22
LIBTRACE_CFLAGS  = -DTARGET=$(BINUTILS_TARGET) -fPIC -I$(BINUTILS_SOURCE)/bfd -I$(BINUTILS_SOURCE)/include -I$(BINUTILS_SOURCE)/binutils -I. -Wall -O4
LIBTRACE_LDFLAGS = -lbfd -liberty -lz #-L$(BINUTILS_SOURCE)/bfd -L$(BINUTILS_SOURCE)/libiberty

TARGET		= thread-pool-server
TARGET_SRC	= handler_thread.c handler_threads_pool.c main.c requests_queue.c
TARGET_OBJ      = $(TARGET_SRC:%.c=%.o)
TARGET_FLAGS	= -rdynamic -Wall -Wno-unused-but-set-variable -lpthread



all: $(TARGET) libpthread_wrapper.so

$(TARGET): $(TARGET_SRC)
	$(CC) $^ -o $@ $(TARGET_FLAGS)

libpthread_wrapper.so: libpthread_wrapper.o trace.o
	$(LD) -shared -o libpthread_wrapper.so libpthread_wrapper.o trace.o $(LIBTRACE_LDFLAGS) -ldl -lrt

trace.o: trace.c libtrace.h Makefile
	$(CC) -c $< -o $@ $(LIBTRACE_CFLAGS)

libpthread_wrapper.o: libpthread_wrapper.c
	$(CC) -Wall -fPIC -DPIC -c libpthread_wrapper.c

%.o: %.c
	$(CC) $(CFLAGS) -c $<

run: all
	./run.sh $(TARGET)

.IGNORE: clean 
clean:
	@rm -f $(TARGET) libpthread_wrapper.so *.o

