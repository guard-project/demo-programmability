function k8s-start {
    echo Namespace
    kubectl apply -f namespace
    echo

    echo Storage
    k8s apply -f storage
    echo

    echo Map
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
    k8s create configmap ssh-server-cubebeat --from-file=$SSH_SERVER_DIR/cubebeat/cubebeat.yml \
                                                --from-file=$SSH_SERVER_DIR/cubebeat/config.d/synflood.yml
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
    k8s create configmap context-broker-elasticsearch --from-file=$CONTEXT_BROKER_DIR/elasticsearch/elasticsearch.keystore \
                                                         --from-file=$CONTEXT_BROKER_DIR/elasticsearch/elasticsearch.yml \
                                                         --from-file=$CONTEXT_BROKER_DIR/elasticsearch/jvm.options \
                                                         --from-file=$CONTEXT_BROKER_DIR/elasticsearch/log4j2.properties
    k8s create configmap context-broker-kibana --from-file=$CONTEXT_BROKER_DIR/kibana/kibana.yml
    echo

    echo Service
    k8s apply -f service
    echo

    echo Context broker
    k8s apply -f pod/context-broker.pod.yaml
    init_done=0
    while [ $init_done -eq 0 ]; do
        k8s exec deploy/context-broker -c elasticsearch -- curl localhost:9200 && init_done=1
        echo "Waiting additional 30 seconds to initialize elasticsearch in context-broker"
        sleep 30
    done
    k8s-pod-vars -p context-broker
    echo POD context-broker=$context_broker
    echo

    echo Elastic Fix
    k8s cp -c elasticsearch $RESOURCES_DIR/context-broker/elasticsearch/fix-index.json $context_broker:/usr/share/elasticsearch/fix-index.json
    k8s exec deploy/context-broker -c elasticsearch -- curl -XDELETE localhost:9200/polycube
    k8s exec deploy/context-broker -c elasticsearch -- curl -XPUT -d "@fix-index.json" -H 'Content-Type:application/json' localhost:9200/polycube
    echo

    echo Kibana Update
    k8s cp -c kibana $RESOURCES_DIR/context-broker/kibana/kibana-milestones-vis-6.8.1.zip $context_broker:/usr/share/kibana/resources/kibana-milestones-vis-6.8.1.zip
    k8s cp -c kibana $RESOURCES_DIR/context-broker/kibana/datasweet_formula-2.1.2_kibana-6.8.1.zip $context_broker:/usr/share/kibana/resources/datasweet_formula-2.1.2_kibana-6.8.1.zip
    k8s exec deploy/context-broker -c kibana -- bin/kibana-plugin install file:///usr/share/kibana/resources/kibana-milestones-vis-6.8.1.zip
    k8s exec deploy/context-broker -c kibana -- bin/kibana-plugin install file:///usr/share/kibana/resources/datasweet_formula-2.1.2_kibana-6.8.1.zip
    echo

    echo Execution Environments
    echo - Apache
    k8s apply -f pod/apache.pod.yaml
    echo - MySQL
    k8s apply -f pod/mysql.pod.yaml
    echo - SSH-Server
    k8s apply -f pod/ssh-server.pod.yaml
    echo

    pause "Wait until the pods are running (use k8s-pod in another terminal)."
    k8s exec deploy/apache -c apache -- rm -rf /usr/local/apache2/logs/access.log
    k8s exec deploy/apache -c apache -- touch /usr/local/apache2/logs/access.log

    echo "Open kibana at http::/localhost:5061"
    k8s-frwd -t kibana
}

function k8s-frwd {
    function usage {
        echo "Usage: k8s-frwd [ -h ] [ -t elastic|kibana|polycube ]"
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
                    "elastic")  port=9200
                                pod=context-broker
                                ;;
                    "kibana")   port=5601
                                pod=context-broker
                                ;;
                    "polycube") port=9000
                                pod=ssh-server
                                ;;
                    *)          echo Error: wrong argument for -s.
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
        echo Error: missing target: elastic, polycube or kibana.
        usage
        return 1
    fi

    k8s port-forward -v=0 --address=0.0.0.0 deploy/$pod $port:$port
}
