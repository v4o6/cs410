#!/bin/sh

export CTRACE_PROGRAM=./ctraced
LD_PRELOAD=./libctrace.so ./ctraced 

