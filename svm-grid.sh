#!/usr/bin/env bash

while [[ $# > 0 ]]; do
    KEY="$1"
    case $KEY in
	-d|--data)
	    DATA="$2"
    esac
    shift
done

function hasuser {
    [[ -z $(users | sed "s/$USERS//" ]] && echo "unused"
}

export -f hasuser

function unused {
    parallel --plain				\
             --sshloginfile ..			\
             --nonall				\
             --tag				\
             hasuser				\
    | sed -e 's/\s*unused//'			\
          -e 's/^/4\//'
}

function exit_parallel {			\
    trap '' SIGINT SIGQUIT			\
    parallel --plain				\
             --sshloginfile ..			\
             --nonall				\
             'killall -q -u $USER svm-train'
}

function train {
    nice svm-train -q				\
	 -m 1024				\
	 -h 0					\
	 -v 5					\
	 -c $(echo "2^$1" | bc -l)		\
	 -g $(echo "2^$2" | bc -l)		\
	 "$(basename "$DATA")"			\
	| sed 's/Cross .* = //;s/%//'
}

export -f train

cd /tmp/
cp "$DATA" .

trap 'echo "Ctrl-C detected.";			\
      exit_parallel;				\
      exit 130'					\
     SIGINT SIGQUIT

parallel --workdir "/tmp"			\
	 --basefile "$(basename "$DATA")"	\
	 --line-buffer				\
	 --plain				\
         --sshloginfile <(unused)		\
         --filter-hosts				\
         --retries 10				\
         --timeout 28800			\
         --tag					\
	 'train {1} {2}'			\
         ::: {-5..15..2}			\
         ::: {3..-15..-2}
