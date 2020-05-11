function k8s-pod-vars {
    function usage {
        echo "Usage: k8-pod-vars [ -h ] [ -p <pod> ]"
    }

    OPTIND=1
    unset pod
    while getopts "hd:p:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    rm -rf ~*.tmp
    k8s get deployments > ~ds.tmp 2> /dev/null
    num=$(cat ~ds.tmp | wc -l )
    cat ~ds.tmp | awk 'NR != 1 { print $1 }' | sort > ~ds-2.tmp
    sed -i.~~~.tmp "s/-/_/g" ~ds-2.tmp
    k8s get pods -o wide > ~pods.tmp
    cat ~pods.tmp | awk 'NR != 1 { print $1 }' | sort > ~pods-2.tmp
    paste -d = ~ds-2.tmp ~pods-2.tmp > ~assign.tmp
    if [ -s "~assign.tmp" ]; then
        if [ -z "$pod" ]; then
            export $(cat ~assign.tmp | xargs)
            echo Set the variables:
            cat ~assign.tmp
        else
            export $(cat ~assign.tmp | grep $pod | xargs)
        fi
    fi
    rm -rf ~*.tmp
}

function k8s-reset {
    echo Pods / Deployments
    k8s delete deployments --all
    echo

    echo Services
    k8s delete services --all
    echo

    echo Map
    k8s delete configmap --all
    echo

    echo Storage
    k8s delete pvc --all
    k8s delete pv --all
    echo

    echo Namespace
    kubectl delete namespace guard-kube
    echo
}

function k8s-bash {
    function usage {
        echo "Usage: k8-bash [ -h ] [ -p <pod> ]"
    }

    OPTIND=1
    unset pod
    while getopts "hd:p:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
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

    k8s exec $pod -c polycubed -it -- /bin/bash
}