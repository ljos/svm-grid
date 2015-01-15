NR == 1 {
    n = $1
    print
    next
}

{
    if (n != $1) {
        printf "\n"
    }
    n = $1
    print
}
