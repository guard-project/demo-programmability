function k8s-start {
    function usage {
        echo "Usage: k8s-start [ -h ] [ -v 6.8.1|7.0.1 ] [ -s ] [ -c ] [ -p ] [ -e ]"
    }

    OPTIND=1
    unset elk_version
    reset_storage=0
    reset_configmap=0
    reset_pod=0
    reset_service=0
    while getopts "hv:scp" opt; do
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
            p)  reset_pod=1
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
        k8s create configmap apache-conf --from-file=$APACHE_DIR/apache/conf/httpd.conf
        k8s create configmap apache-filebeat --from-file=$APACHE_DIR/filebeat/filebeat.yml \
                                                --from-file=$APACHE_DIR/filebeat/config/log.yml
        k8s create configmap apache-metricbeat --from-file=$APACHE_DIR/metricbeat/metricbeat.yml \
                                                --from-file=$APACHE_DIR/metricbeat/modules.d/system.yml
        k8s create configmap apache-logstash --from-file=$APACHE_DIR/logstash/logstash.yml \
                                                --from-file=$APACHE_DIR/logstash/pipelines.yml \
                                                --from-file=$APACHE_DIR/logstash/log4j2.properties \
                                                --from-file=$APACHE_DIR/logstash/conf.d/apache.conf \
                                                --from-file=$APACHE_DIR/logstash/conf.d/system.conf
        # mysql
        k8s create configmap mysql-conf --from-file=$MYSQL_DIR/mysql/my.cnf
        k8s create configmap mysql-metricbeat --from-file=$MYSQL_DIR/metricbeat/metricbeat.yml \
                                                --from-file=$MYSQL_DIR/metricbeat/modules.d/mysql.yml \
                                                --from-file=$MYSQL_DIR/metricbeat/modules.d/system.yml
        k8s create configmap mysql-logstash --from-file=$MYSQL_DIR/logstash/logstash.yml \
                                                --from-file=$MYSQL_DIR/logstash/pipelines.yml \
                                                --from-file=$MYSQL_DIR/logstash/log4j2.properties \
                                                --from-file=$MYSQL_DIR/logstash/conf.d/mysql-system.conf
        # ssh-server
        k8s create configmap ssh-server-cubebeat --from-file=$SSH_SERVER_DIR/cubebeat/config.d/synflood.yml
        k8s create configmap ssh-server-metricbeat --from-file=$SSH_SERVER_DIR/metricbeat/metricbeat.yml \
                                                --from-file=$SSH_SERVER_DIR/metricbeat/modules.d/system.yml
        k8s create configmap ssh-server-logstash --from-file=$SSH_SERVER_DIR/logstash/logstash.yml \
                                                    --from-file=$SSH_SERVER_DIR/logstash/pipelines.yml \
                                                    --from-file=$SSH_SERVER_DIR/logstash/log4j2.properties \
                                                    --from-file=$SSH_SERVER_DIR/logstash/conf.d/ssh-server.conf \
                                                    --from-file=$SSH_SERVER_DIR/logstash/conf.d/system.conf
        # context-broker
        k8s create configmap context-broker-logstash --from-file=$CONTEXT_BROKER_DIR/logstash/logstash.yml \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/pipelines.yml \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/log4j2.properties \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/conf.d/apache.conf \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/conf.d/mysql.conf \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/conf.d/ssh-server.conf \
                                                        --from-file=$CONTEXT_BROKER_DIR/logstash/conf.d/system.conf
        k8s create configmap context-broker-elasticsearch --from-file=$CONTEXT_BROKER_DIR/elasticsearch/elasticsearch-$elk_version.yml \
                                                          --from-file=$CONTEXT_BROKER_DIR/elasticsearch/log4j2.properties
        k8s create configmap context-broker-kibana --from-file=$CONTEXT_BROKER_DIR/kibana/kibana.yml
        echo
    fi

    if [ $reset_service -eq 1 ]; then
        echo Service
        k8s delete configmap --all
        k8s apply -f service
        echo
    fi

    echo Context broker
    k8s apply -f pod/context-broker-$elk_version.pod.yaml
    wait-done -p context-broker -c elasticsearch -t 9200 -s 2
    k8s-pod-vars -p context-broker
    echo POD context-broker=$context_broker
    echo

    echo Elastic Fix
    k8s cp -c elasticsearch $RESOURCES_DIR/context-broker/elasticsearch/fix-index.json $context_broker:/usr/share/elasticsearch/fix-index.json
    k8s exec deploy/context-broker -c elasticsearch -- curl -XDELETE localhost:9200/ssh-server
    k8s exec deploy/context-broker -c elasticsearch -- curl -XPUT -d "@fix-index.json" -H 'Content-Type:application/json' localhost:9200/ssh-server
    echo

    # echo Kibana Update
    k8s cp -c kibana $RESOURCES_DIR/context-broker/kibana/kibana-milestones-vis-$elk_version.zip $context_broker:/usr/share/kibana/resources/kibana-milestones-vis-$elk_version.zip
    k8s cp -c kibana $RESOURCES_DIR/context-broker/kibana/datasweet_formula-2.1.2_kibana-$elk_version.zip $context_broker:/usr/share/kibana/resources/datasweet_formula-2.1.2_kibana-$elk_version.zip
    k8s exec deploy/context-broker -c kibana -- bin/kibana-plugin install file:///usr/share/kibana/resources/kibana-milestones-vis-$elk_version.zip
    k8s exec deploy/context-broker -c kibana -- bin/kibana-plugin install file:///usr/share/kibana/resources/datasweet_formula-2.1.2_kibana-$elk_version.zip
    # echo

    echo Execution Environments
    echo - Apache
    k8s apply -f pod/apache-$elk_version.pod.yaml
    echo - MySQL
    k8s apply -f pod/mysql-$elk_version.pod.yaml
    echo - SSH-Server
    k8s apply -f pod/ssh-server-$elk_version.pod.yaml
    echo

    wait-done -p apache -c filebeat -t 80 -s 2
    k8s exec deploy/apache -c apache -- rm -rf /usr/local/apache2/logs/access.log
    k8s exec deploy/apache -c apache -- touch /usr/local/apache2/logs/access.log

    wait-done -p ssh-server -c ssh-server -n -t 22 -s 2
    k8s exec deploy/ssh-server -c ssh-server -- apk add hping3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing
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