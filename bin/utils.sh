function pause {
    ( [ -z "$1" ] && echo "Press any key to continue..." ) || echo $1
    read -n1
}

function wait-done {
function usage {
        echo "Usage: wait-done [ -h ] [ -p <pod> -c <container> -t <target> ] [ -n ] [ -s <second> ]"
    }

    OPTIND=1
    unset pod
    unset container
    unset target
    unset cmd
    seconds=30
    cmd="curl"
    while getopts "hp:c:t:s:n" opt; do
        case "$opt" in
            h)  usage
                  return 0
                ;;
            p)  pod=$OPTARG
                ;;
            c)  container=$OPTARG
                ;;
            t)  target=$OPTARG
                ;;
            n)  cmd="nc -z"
                ;;
            s)  seconds=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$pod" ]; then
        echo Error: missing pod.
        usage
        return 1
    fi

    if [ -z "$container" ]; then
        echo Error: missing container.
        usage
        return 1
    fi

    if [ -z "$target" ]; then
        echo Error: missing target.
        usage
        return 1
    fi

    init_done=0
    echo -e "Waiting to initialize $pod\c"
    while [ $init_done -eq 0 ]; do
        k8s exec deploy/$pod -c $container -- $cmd localhost:$target  > /dev/null 2> /dev/null && init_done=1
        if [ $init_done -eq 0 ]; then
            echo -e ".\c"
            sleep $seconds
        fi
    done
    echo
    echo "$pod correctly initialized"
}