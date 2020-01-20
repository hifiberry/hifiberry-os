#!/bin/bash
for baseaddr in 0xf61 0xf62 0xf63 0xf64; do
  line="";
  for i in 0 2 4 6 8 a; do
    j=`dsptoolkit read-hex $baseaddr$i`
    line="$line $j"
  done
  echo $baseaddr $line
done
