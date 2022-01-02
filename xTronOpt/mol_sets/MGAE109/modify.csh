#!/bin/csh -f
foreach file (*.in)
sed -f sub.sed $file > temp
mv temp $file
end
