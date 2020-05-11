source bin/utils.sh

alias k8s-node="kubectl get nodes -o wide"

source bin/k8s-core.sh

alias k8s="kubectl -n guard-kube"
alias k8s-get="k8s get -o wide"
alias k8s-desc="k8s describe pods"
alias k8s-log="k8s logs"
alias k8s-pod="k8s-get pods"
alias k8s-serv="k8s-get services"
alias k8s-map="k8s-get configmaps"

export WORKSPACE_DIR=$(pwd)

export RESOURCES_DIR=$WORKSPACE_DIR/resources
export APACHE_DIR=$RESOURCES_DIR/apache
export MYSQL_DIR=$RESOURCES_DIR/mysql
export SSH_SERVER_DIR=$RESOURCES_DIR/ssh-server
export CONTEXT_BROKER_DIR=$RESOURCES_DIR/context-broker

source bin/k8s-base.sh
source bin/k8s-generator.sh
source bin/k8s-period.sh
