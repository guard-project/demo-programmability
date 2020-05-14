function k8s-period-metricbeat {
    function usage {
        echo "Usage: $0 [ -h ] [ -p <pod> -m mysql|system [ -s <period> ] ]"
    }

    OPTIND=1
    unset pod
    unset module
    unset period
    while getopts "hp:m:s:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
                ;;
            m)  module=$OPTARG
                case "$module" in
                    mysql)  ;;
                    system) ;;
                    *)      echo Error: wrong argument for -m.
                            usage
                            return 1
                esac
                ;;
            s)  period=$OPTARG
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

    if [ -z "$module" ]; then
        echo Error: missing module: mysql or system.
        usage
        return 1
    fi

    if [ -n "$period" ]; then
        k8s exec $pod -c metricbeat -- sed -i "s/period:.*/period: $period/g" modules.d/$module.yml
    fi

    k8s exec $pod -c metricbeat -- cat modules.d/$module.yml | grep period
}

function k8s-period-filebeat {
    function usage {
        echo "Usage: k8s-period-filebeat [ -h ] [ -p <pod> [ -s <period> ] ]"
    }

    OPTIND=1
    unset pod
    unset period
    while getopts "hp:s:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
                ;;
            s)  period=$OPTARG
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

    if [ -n "$period" ]; then
        k8s exec $pod -c filebeat -- sed -i "s/backoff:.*/backoff: $period/g" config/log.yml
    fi

    k8s exec $pod -c filebeat -- cat config/log.yml | grep backoff: | sed s/backoff/period/g
}

function k8s-period-cubebeat {
    function usage {
        echo "Usage: k8s-period-cubebeat [ -h ] [ -p <pod> [ -s <period> ] ]"
    }

    OPTIND=1
    unset pod
    unset period
    while getopts "hp:s:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
                ;;
            s)  period=$OPTARG
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

    config_file=/root/go/src/gitlab.com/guard-repositories/cubebeat/config.d/synflood.yml

    if [ -n "$period" ]; then
        k8s exec $pod -c cubebeat -- sed -i "s/period:.*/period: $period/g" $config_file
    fi

    k8s exec $pod -c cubebeat -- cat $config_file | grep period
}
