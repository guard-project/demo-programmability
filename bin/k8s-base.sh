function k8s-start {
    function usage {
        echo "Usage: k8s-start [ -h ] [ -v 6.8.1|7.0.1 ] [ -s ] [ -c ] [ -e ]"
    }

    OPTIND=1
    unset elk_version
    reset_storage=0
    reset_configmap=0
    reset_service=0
    while getopts "hv:sce" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            v)  elk_version=$OPTARG
                ;;
            s)  reset_storage=1
                ;;
            c)  reset_configmap=1
                ;;
            e)  reset_service=1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$elk_version" ]; then
        echo Error: missing ELK version. It can be: 6.8.1 or 7.0.1.
        usage
        return 1
    fi

    echo Namespace
    kubectl apply -f namespace
    echo

    echo Delete old deployments
    k8s delete deployments --all
    echo

    if [ $reset_storage -eq 1 ]; then
        echo Storage
        k8s delete pvc --all
        k8s delete pv --all
        k8s apply -f storage/elasticsearch-$elk_version.storage.yaml
        k8s apply -f storage/kibana-$elk_version.storage.yaml
        echo
    fi

    if [ $reset_configmap -eq 1 ]; then
        echo Map
        k8s delete configmap --all

        # apache
        k8s create configmap apache-conf --from-file=$APACHE_DIR/apache/conf

        k8s create configmap apache-filebeat        --from-file=$APACHE_DIR/filebeat
        k8s create configmap apache-filebeat-config --from-file=$APACHE_DIR/filebeat/config

        k8s create configmap apache-metricbeat         --from-file=$APACHE_DIR/metricbeat
        k8s create configmap apache-metricbeat-modules --from-file=$APACHE_DIR/metricbeat/modules.d

        k8s create configmap apache-heartbeat          --from-file=$APACHE_DIR/heartbeat
        k8s create configmap apache-heartbeat-monitors --from-file=$APACHE_DIR/heartbeat/monitors.d

        k8s create configmap apache-logstash-config   --from-file=$APACHE_DIR/logstash/config
        k8s create configmap apache-logstash-pipeline --from-file=$APACHE_DIR/logstash/pipeline

        # mysql
        k8s create configmap mysql-metricbeat         --from-file=$MYSQL_DIR/metricbeat
        k8s create configmap mysql-metricbeat-modules --from-file=$MYSQL_DIR/metricbeat/modules.d

        k8s create configmap mysql-heartbeat          --from-file=$MYSQL_DIR/heartbeat
        k8s create configmap mysql-heartbeat-monitors --from-file=$MYSQL_DIR/heartbeat/monitors.d

        k8s create configmap mysql-logstash-config   --from-file=$MYSQL_DIR/logstash/config
        k8s create configmap mysql-logstash-pipeline --from-file=$MYSQL_DIR/logstash/pipeline

        # ssh-server
        k8s create configmap ssh-server-cubebeat        --from-file=$SSH_SERVER_DIR/cubebeat
        k8s create configmap ssh-server-cubebeat-config --from-file=$SSH_SERVER_DIR/cubebeat/config.d

        k8s create configmap ssh-server-metricbeat         --from-file=$SSH_SERVER_DIR/metricbeat
        k8s create configmap ssh-server-metricbeat-modules --from-file=$SSH_SERVER_DIR/metricbeat/modules.d

        k8s create configmap ssh-server-heartbeat          --from-file=$SSH_SERVER_DIR/heartbeat
        k8s create configmap ssh-server-heartbeat-monitors --from-file=$SSH_SERVER_DIR/heartbeat/monitors.d

        k8s create configmap ssh-server-logstash-config   --from-file=$SSH_SERVER_DIR/logstash/config
        k8s create configmap ssh-server-logstash-pipeline --from-file=$SSH_SERVER_DIR/logstash/pipeline

        # context-broker
        k8s create configmap context-broker-metricbeat         --from-file=$CONTEXT_BROKER_DIR/metricbeat
        k8s create configmap context-broker-metricbeat-modules --from-file=$CONTEXT_BROKER_DIR/metricbeat/modules.d

        k8s create configmap context-broker-heartbeat          --from-file=$CONTEXT_BROKER_DIR/heartbeat
        k8s create configmap context-broker-heartbeat-monitors --from-file=$CONTEXT_BROKER_DIR/heartbeat/monitors.d

        k8s create configmap context-broker-logstash-config   --from-file=$CONTEXT_BROKER_DIR/logstash/config
        k8s create configmap context-broker-logstash-pipeline --from-file=$CONTEXT_BROKER_DIR/logstash/pipeline

        k8s create configmap context-broker-elasticsearch-config --from-file=$CONTEXT_BROKER_DIR/elasticsearch/config

        k8s create configmap context-broker-kibana-config --from-file=$CONTEXT_BROKER_DIR/kibana/config

        echo
    fi

    if [ $reset_service -eq 1 ]; then
        echo Service
        k8s delete service --all
        k8s apply -f service
        echo
    fi

    echo Context broker
    k8s apply -f pod/context-broker-$elk_version.pod.yaml
    wait-done -p context-broker -c elasticsearch -t 9200 -s 2
    echo

    echo Elastic Fix
    k8s exec deploy/context-broker -c elasticsearch -- curl -s -XDELETE localhost:9200/ssh-server | jq
    echo

    echo Node
    k8s apply -f pod/node.pod.yaml
    echo

    echo Execution Environments
    echo

    echo Apache
    k8s apply -f pod/apache-$elk_version.pod.yaml
    echo

    echo MySQL
    k8s apply -f pod/mysql-$elk_version.pod.yaml
    echo

    echo SSH-Server
    k8s apply -f pod/ssh-server-$elk_version.pod.yaml
    wait-done -p ssh-server -c ssh-server -n -t 22 -s 2
    echo
}

function k8s-frwd {
    function usage {
        echo "Usage: k8s-frwd [ -h ] [ -t cb-manager|kibana|elasticsearch ]"
    }

    OPTIND=1
    unset target
    while getopts "ht:" opt; do
        case "$opt" in
            h)  usage
                  return 0
                ;;
            t)  target=$OPTARG
                case "$target" in
                    "kibana")        port=5601
                                     pod=context-broker
                                     ;;
                    "cb-manager")    port=5000
                                     pod=context-broker
                                     ;;
                    "elasticsearch") port=9200
                                     pod=context-broker
                                     ;;
                    *)               echo Error: wrong argument for -s.
                                     usage
                                     return 1
                esac
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$target" ]; then
        echo Error: missing target: cb-manager or kibana.
        usage
        return 1
    fi

    k8s port-forward -v=0 --address=0.0.0.0 deploy/$pod $port:$port
}

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

function k8s-shell {
    function usage {
        echo "Usage: k8s-shell [ -h ] [ -p <pod> -c <container> ] [ -s <shell-command-path> ]"
    }

    OPTIND=1
    unset pod
    unset container
    shell=/bin/bash
    while getopts "hd:p:c:s:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            p)  pod=$OPTARG
                ;;
            c)  container=$OPTARG
                ;;
            s)  shell=$OPTARG
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

    k8s exec $pod -c $container -it -- $shell
}

function k8s-log-level {
    function usage {
        echo "Usage: k8s-log-level [ -h ] [ -l <log-level> ]"
    }

    OPTIND=1
    unset log_level
    while getopts "hl:" opt; do
        case "$opt" in
            h)  usage
                return 0
                ;;
            l)  log_level=$OPTARG
                ;;
            ?)  echo Error: -$OPTARG requires an argument.
                usage
                return 1
                ;;
            *)  usage
                return 1
        esac
    done

    if [ -z "$log_level" ]; then
        echo Error: missing log-level.
        usage
        return 1
    fi

    find $RESOURCES_DIR -type f -name '*.yml' -exec sed -i "s/level:.*/level: $log_level/g" {} \;
}

function k8s-pod-node {
    kubectl apply -f namespace/guard.namespace.yaml
    k8s delete pod node
    k8s apply -f node/node.pod.yaml
}