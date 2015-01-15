set term png transparent small linewidth 2 medium enhanced
set output ARG1 . ".png"
set xlabel "log2(C)"
set ylabel "log2(gamma)"
set xrange [-5 to 15]
set yrange [3 to -15]
set contour
set cntrparam levels incremental 0,0.5,100
unset surface
unset ztics
set view 0,0
set title ARG1
unset label
set label                                       \
    "Best log2(c) = " . ARG2 .                  \
    ", log2(gamma) = " . ARG3 .                 \
    ", accuracy = " . ARG4                      \
    at screen 0.5,0.85 center
set label                                       \
    "C = "     . @ARG2**2 .                     \
    ", gamma = " . @ARG3**2                     \
    at screen 0.5,0.8 center
set key at screen 0.9,0.9
splot ARG1 with lines
