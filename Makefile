CC = gcc
CFLAGS = -Wall -Wextra -g
TARGET = uav_node

all: $(TARGET)

$(TARGET): uav_node.c
	$(CC) $(CFLAGS) -o $(TARGET) uav_node.c

clean:
	rm -f $(TARGET)
