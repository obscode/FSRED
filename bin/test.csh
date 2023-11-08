#!/bin/csh 
set nx = 5
set ny = 5

@ x = 0
while ($x != $nx)
    @ y = 0 
    while ($y != $ny)
	@ x1 = $x * 20
	echo $x1
	@ y++
    end
    @ x++
end

exit 0
