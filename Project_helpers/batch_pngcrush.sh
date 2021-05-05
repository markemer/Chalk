#!/bin/sh
for i in $*; do
  pngcrush $i tmp.png
  mv -f tmp.png $i
done
