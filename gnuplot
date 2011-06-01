set size 1.0, 0.6
#set terminal postscript portrait enhanced mono dashed lw 1 "Helvetica" 14
set terminal postscript landscape enhanced color solid lw 1 "Helvetica" 14

set xdata time
set timefmt "%Y-%m-%d"

# full data
set output "Stromexport.ps"
plot \
"./2009.post" using 1:2 with lines title "Deutschland: Stromexport (2009) [GWh / Tag]", \
"./2010.post" using 1:2 with lines title "Deutschland: Stromexport (2010) [GWh / Tag]", \
"./2011.post" using 1:2 with lines title "Deutschland: Stromexport (2011) [GWh / Tag]", \
0 title ""

# 7 day average
set output "Stromexport_7Tage.ps"
plot \
"./2009.post" using 1:3 with lines title "Deutschland: Stromexport (2009) [GWh / Tag]", \
"./2010.post" using 1:3 with lines title "Deutschland: Stromexport (2010) [GWh / Tag]", \
"./2011.post" using 1:3 with lines title "Deutschland: Stromexport (2011) [GWh / Tag]", \
0 title ""

# 30 day average
set output "Stromexport_30Tage.ps"
plot \
"./2009.post" using 1:4 with lines title "Deutschland: Stromexport (2009) [GWh / Tag]", \
"./2010.post" using 1:4 with lines title "Deutschland: Stromexport (2010) [GWh / Tag]", \
"./2011.post" using 1:4 with lines title "Deutschland: Stromexport (2011) [GWh / Tag]", \
0 title ""

# cumulative
set output "Stromexport_kumulativ.ps"
plot \
"./2009.post" using 1:5 with lines title "Deutschland: kumulierter Stromexport (2009) [GWh]", \
"./2010.post" using 1:5 with lines title "Deutschland: kumulierter Stromexport (2010) [GWh]", \
"./2011.post" using 1:5 with lines title "Deutschland: kumulierter Stromexport (2011) [GWh]", \
0 title ""
