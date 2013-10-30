#!/bin/bash
# Runs command to build image from dot file.
# Must have graphviz installed.
# On Ubuntu:
# sudo apt-get install graphviz

dot -Tpng input.dot > output.png