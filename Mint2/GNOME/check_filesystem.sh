#!/bin/bash
df -hT | grep /$ | awk '{ print $2 }' | while read output;
do
  echo $output
done
