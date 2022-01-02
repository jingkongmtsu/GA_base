w=$1
#new W1-F12 reference values
# get dE(CH4-CH3) for RSE calculation	
d0CH4=$( tmer2_GMTKN   E1   P1    x 1  -1    $w | awk '{ print $6; }' )

#echo $d0CH4

#~/bin/tmer/tmer2   E1   P1    x -1   1    $w     0.0    $d0CH4  # need for dE, not part of the set
tmer2_GMTKN   E2   P2    x -1   1    $w   -15.3    $d0CH4  
tmer2_GMTKN   E3   P3    x -1   1    $w     2.0    $d0CH4
tmer2_GMTKN   E4   P4    x -1   1    $w     6.9    $d0CH4
tmer2_GMTKN   E5   P5    x -1   1    $w    -0.7    $d0CH4
tmer2_GMTKN   E6   P6    x -1   1    $w     0.1    $d0CH4
tmer2_GMTKN   E7   P7    x -1   1    $w     1.4    $d0CH4
tmer2_GMTKN   E8   P8    x -1   1    $w    -3.0    $d0CH4
tmer2_GMTKN   E9   P9    x -1   1    $w    -1.5    $d0CH4
tmer2_GMTKN   E10  P10   x -1   1    $w    -2.0    $d0CH4
tmer2_GMTKN   E11  P11   x -1   1    $w   -17.7    $d0CH4
tmer2_GMTKN   E12  P12   x -1   1    $w   -10.1    $d0CH4
tmer2_GMTKN   E13  P13   x -1   1    $w    -8.4    $d0CH4
tmer2_GMTKN   E15  P15   x -1   1    $w    -6.4    $d0CH4
tmer2_GMTKN   E16  P16   x -1   1    $w    -6.5    $d0CH4
tmer2_GMTKN   E17  P17   x -1   1    $w    -6.6    $d0CH4
tmer2_GMTKN   E18  P18   x -1   1    $w    -6.5    $d0CH4
tmer2_GMTKN   E19  P19   x -1   1    $w    -3.1    $d0CH4
tmer2_GMTKN   E20  P20   x -1   1    $w    -3.8    $d0CH4
tmer2_GMTKN   E21  P21   x -1   1    $w   -12.5    $d0CH4
tmer2_GMTKN   E22  P22   x -1   1    $w     4.7    $d0CH4
tmer2_GMTKN   E23  P23   x -1   1    $w   -13.1    $d0CH4
tmer2_GMTKN   E24  P24   x -1   1    $w   -11.2    $d0CH4
tmer2_GMTKN   E25  P25   x -1   1    $w    -8.9    $d0CH4
tmer2_GMTKN   E26  P26   x -1   1    $w   -13.3    $d0CH4
tmer2_GMTKN   E27  P27   x -1   1    $w    -3.5    $d0CH4
tmer2_GMTKN   E28  P28   x -1   1    $w    -3.8    $d0CH4
tmer2_GMTKN   E29  P29   x -1   1    $w    -2.9    $d0CH4
tmer2_GMTKN   E30  P30   x -1   1    $w    -6.0    $d0CH4
tmer2_GMTKN   E31  P31   x -1   1    $w    -6.4    $d0CH4
tmer2_GMTKN   E32  P32   x -1   1    $w    -4.3    $d0CH4
tmer2_GMTKN   E33  P33   x -1   1    $w     0.6    $d0CH4
tmer2_GMTKN   E34  P34   x -1   1    $w   -11.5    $d0CH4
tmer2_GMTKN   E35  P35   x -1   1    $w    -9.1    $d0CH4
tmer2_GMTKN   E36  P36   x -1   1    $w     2.4    $d0CH4
tmer2_GMTKN   E37  P37   x -1   1    $w    -10.1    $d0CH4
tmer2_GMTKN   E38  P38   x -1   1    $w    -0.4    $d0CH4
tmer2_GMTKN   E39  P39   x -1   1    $w    -3.5    $d0CH4
tmer2_GMTKN   E40  P40   x -1   1    $w   -23.1    $d0CH4
tmer2_GMTKN   E41  P41   x -1   1    $w   -25.1    $d0CH4
tmer2_GMTKN   E42  P42   x -1   1    $w   -26.4    $d0CH4
tmer2_GMTKN   E43  P43   x -1   1    $w   -13.1    $d0CH4
tmer2_GMTKN   E44  P44   x -1   1    $w    -6.7    $d0CH4
tmer2_GMTKN   E45  P45   x -1   1    $w    -2.3    $d0CH4
