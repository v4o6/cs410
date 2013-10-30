#!/bin/bash
# Creates images from logged data.
# Reads file log.dat in pwd.
# Date: October 30, 2013
# Dependencies:
# - Graphviz (sudo apt-get install graphviz)
# - view/parse.pl 

perl parse.pl
dot -Tpng input.dot > output.png