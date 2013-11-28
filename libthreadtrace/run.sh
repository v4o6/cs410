#!/bin/sh

LD_PRELOAD=./libpthread_wrapper.so $@

