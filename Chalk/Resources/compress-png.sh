#!/bin/bash
FILES=$1
if [[ -z "$FILES" ]]; then
  FILES=`ls *.png`
fi
for i in $FILES; do
  convert "$i" "tmp.png"
  mv -f "tmp.png" "$i"
done
