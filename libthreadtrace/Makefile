CC  = gcc

TARGET		= thread-pool-server # producer_consumer
TARGET_SRC	= handler_thread.c handler_threads_pool.c main.c requests_queue.c #producer_consumer.c
TARGET_OBJ      = $(TARGET_SRC:%.c=%.o)
TARGET_FLAGS	= -rdynamic -lpthread -Wall -Wno-unused-but-set-variable


all: $(TARGET) libpthread_wrapper.so

$(TARGET): $(TARGET_SRC)
	$(CC) $^ -o $@ $(TARGET_FLAGS)

libpthread_wrapper.so: libpthread_wrapper.o
	$(LD) $^ -o $@ -shared -ldl -lrt

libpthread_wrapper.o: libpthread_wrapper.c
	$(CC) -c $< -fPIC -DPIC -Wall

%.o: %.c
	$(CC) $(CFLAGS) -c $<

run: all
	./run.sh ./$(TARGET)

.IGNORE: clean 
clean:
	@rm -f $(TARGET) libpthread_wrapper.so *.o

