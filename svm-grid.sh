#!/usr/bin/env bash

LOGFILE=$(mktemp "XXXX.parallel.log")

function unused {
    parallel --plain                                                \
             --sshloginfile ..                                      \
             --nonall                                               \
             --tag                                                  \
             '[[ -z $(users | sed "s/$USER//") ]] && echo "unused"' \
        | sed -e 's/\s*unused//'                                    \
              -e 's/^/4\//'
}

function exit_parallel {
    trap '' SIGINT SIGQUIT
    parallel --plain                                \
             --sshloginfile ..                      \
             --nonall                               \
             'killall -q -u $USER svm-train'
    rm "$LOGFILE"
}

trap 'echo "Ctrl-C detected.";                  \
          exit_parallel;                        \
          exit 130'                             \
     SIGINT SIGQUIT

DATA="$DOKTORGRAD/aggr/chunks.svm.bin"

parallel --plain                                    \
         --sshloginfile <(unused)                   \
         --filter-hosts                             \
         --joblog "$LOGFILE"                        \
         --resume-failed                            \
         --timeout 28800                            \
         --tag                                      \
         'nice svm-train -q                         \
                         -m 1024                    \
                         -h 0                       \
                         -v 5                       \
                         -c $(echo 2^{1} | bc -l)   \
                         -g $(echo 2^{2} | bc -l)   \
                 "'$DATA'"                          \
              | sed -e "s/Cross .* = //"            \
                    -e "s/%//"'                     \
         ::: {-5..15..2}                            \
         ::: {3..-15..-2}
