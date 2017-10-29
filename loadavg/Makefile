SHELL := /bin/bash

CC := gcc
CWARN := -pedantic -Wall -Wextra -Wshadow -Wpointer-arith -Wcast-qual -Wmissing-prototypes
CSTD := -std=c1x
OPT := -O3

CFLAGS := $(CSTD) $(CWARN) $(OPT)
LDFLAGS := -static -s

.PHONY: all
all: loadavg.exe loadavg_as_one_core.exe

.PHONY: install
install: loadavg.exe loadavg_as_one_core.exe
	mv -t "$$HOME/bin" $?

.PHONY: clean
clean:
	rm -f loadavg.exe

loadavg.exe: loadavg.c
	$(CC) -o $@ $(CFLAGS) $(LDFLAGS) $?

loadavg_as_one_core.exe: loadavg.c
	$(CC) -o $@ $(CFLAGS) $(LDFLAGS) -DAS_ONE_CORE $?
