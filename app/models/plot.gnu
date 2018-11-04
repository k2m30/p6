unset border
set datafile separator ","
set autoscale fix
set key outside bottom center
set title ""
set terminal canvas size 1400,800 mousing lw 0.7
set rmargin 5
set output 'data1.html'
set multiplot
plot "data.csv" using 2:1 title 'pt' with points pointtype 7 pointsize 0.2, "task.csv" using 3:1 title '' with points pointtype 7 pointsize 2, "data.csv" using 2:3 title '' with points pointtype 7 pointsize 0.3
plot "data.csv" using 2:5 title 'velocity' with lines lt 2
#plot "data.csv" using 2:4 title 'error' with lines lw 4 lc 0
unset multiplot
!open ./data1.html
