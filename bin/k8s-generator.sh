function k8s-gen-apache {
    function usage {
        echo "Usage: k8s-gen-apache [ -h ] [ -n <number of requests per second> ]"
    }

    OPTIND=1
    unset n
    while getopts "hn:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            n)  n=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$n" ]; then
        echo Error: missing number of request per second.
        usage
        return 1
    fi

    k8s-pod-vars -p apache
    k8s cp -c apache $APACHE_DIR/generator/flog $apache:/usr/local/apache2/flog
    rm -rf $APACHE_DIR/generator/finished
    while [ ! -e "$APACHE_DIR/generator/finished" ]; do
        start_time=$(date +%s)
        k8s exec deploy/apache -c apache -- sh -c "/usr/local/apache2/flog -f apache_common -n $n >> /usr/local/apache2/logs/access.log"
        end_time=$(date +%s)
        echo [$(date)] Generated $n requests in $(echo "scale=3; $end_time - $start_time" | bc) seconds.
    done
}

function k8s-gen-mysql {
    function usage {
        echo "Usage: k8s-gen-mysql [ -h ] [ -c <number of commands per second per user> -u <number of users> ]"
    }

    OPTIND=1
    unset commands
    unset users
    while getopts "hc:u:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            c)  commands=$OPTARG
                ;;
            u)  users=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$commands" ]; then
        echo Error: missing number of commands per second per user.
        usage
        return 1
    fi
    if [ -z "$users" ]; then
        echo Error: missing number of users.
        usage
        return 1
    fi

    sleep=$(echo "scale=3; 1.0 / $commands / $users" | bc)
    rm -rf $MYSQL_DIR/generator/finished
    while [ ! -e "$MYSQL_DIR/generator/finished" ]; do
        start_time=$(date +%s)
        k8s exec deploy/mysql -c mysql -- mysqlslap -s -u root --auto-generate-sql --auto-generate-sql-execute-number $commands --concurrency $users
        end_time=$(date +%s)
        echo [$(date)] Generated $commands commands for $users users in $(echo "scale=3; $end_time - $start_time" | bc) seconds.
    done
}

function k8s-gen-synflood {
    function usage {
        echo "Usage: k8s-gen-synflood [ -h ] [ -n <number of requests per second> ]"
    }

    OPTIND=1
    unset n
    while getopts "hn:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            n)  n=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$n" ]; then
        echo Error: missing number of requests per second.
        usage
        return 1
    fi

    time=$(echo "scale=3; 1000000 / $n" | bc)
    echo Send requests each $time us
    k8s exec -it deploy/ssh-server -c ssh-server -- hping3 -i u$time -S -w 64 -d 120 --rand-source localhost
}
