#!/bin/bash
FILES=$1
if [[ -z "$FILES" ]]; then
  FILES=`ls *.jpg`
fi
for i in $FILES; do
  convert "$i" "tmp.jpg"
  mv -f "tmp.jpg" "$i"
done
