#!/usr/bin/env bash

function usage () {
    cat <<EOF
Usage: svm-grid.sh [-w] DATA
    -w    Working directory on remote machines.
EOF
    exit 0
}

while getopts "w:h" OPT; do
    case "$OPT" in
	w)
	    WORKDIR="$OPTARG" ;;
	h|help)
	    usage ;;
	\?)
	    echo "Unexpected option."
	    usage ;;
    esac
done

shift $(($OPTIND - 1))

if [ -z "$1" ]; then
    echo "No data file precent."
    usage
fi

cp "$1" "$WORKDIR/data.svm.bin"

parallel --plain				\
	 --sshloginfile ..			\
	 --nonall				\
	 "mkdir -p $WORKDIR; hostname"		\
    | pv --timer --line-mode --bytes	      	\
    | cat >/dev/null

cd "$WORKDIR"
echo "Done."

function unused {
    function hasuser {
	[[ -z $(users | sed "s/$USER//") ]] && echo "unused"
    }
    export -f hasuser

    parallel --plain				\
	     --env hasuser			\
             --sshloginfile ..			\
             --nonall				\
             --tag				\
             hasuser				\
	| sed -e 's/\s*unused//'		\
              -e 's/^/4\//'
}

function exit_parallel {
    trap '' SIGINT SIGQUIT                      \
    parallel --plain                            \
             --sshloginfile ..                  \
             --nonall                           \
             'killall -q -u $USER svm-train'
}

trap 'echo "Ctrl-C detected.";                  \
      exit_parallel;                            \
      exit 130'                                 \
     SIGINT SIGQUIT

function train {
    svm-train  -q				\
	       -m 1024				\
	       -h 0				\
	       -v 5				\
	       -c $(echo "2^$1" | bc -l)	\
	       -g $(echo "2^$2" | bc -l)	\
	       data.svm.bin           		\
        | sed 's/Cross .* = //;s/%//'
}

export -f train


parallel --workdir "$WORKDIR"			\
         --basefile data.svm.bin       		\
	 --env DATA				\
	 --env train				\
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
