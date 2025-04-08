#!/bin/bash

# input file
input_file=$1

# output file
output_file="${input_file%.png}_transparent.png"

# convert white (also shades of whites)
# colors to transparent
convert "$input_file" -transparent white "$output_file"

