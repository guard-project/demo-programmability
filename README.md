# Demo Programmability for GUARD

## Requirements

- ```bash``` as shell.
- ```kubectl```.

## Installation Steps

1. Go to the directory.

   ```console
   cd demo-programmability
   ```

2. Apply configuration.

   ```console
   source bin/config.sh
   ```

3. Start demo

   ```console
   k8s-start
   ```

4. Open **Kibana** the browser at ```http://localhost:5601```.
   In Management > Saved Object import the JSON ```demo-programmability/resources/context-broker/kibana/saved-objects-$elk_version.json```
   where $elk_version is the version of Elastic stack (at this moment: 6.8.1 or 7.0.1).

## Traffic Generator

### Apache

```console
k8s-gen-apache -n <number of request per second>
```

### Mysql

Generate <number of commands> x <number of users> requests per second.

```console
k8s-gen-mysql -c <number of commands per second per user> -u <number of users>
```

### SynFlood

Generate <number of requests per seconds> requests.

```console
k8s-gen-synflood -n <number of requests per seconds>
```

## Log Collector period

Set the period to collect data by the agents.

### Apache

- Filebeat

  ```console
  k8s-period-filebeat -p deploy/apache - s <period>
  ```

  E.g.: ```k8s-period-filebeat -p deploy/apache -s 10s```

### Mysql

- Metricbeat

  ```console
  k8s-period-metricbeat -p deploy/mysql -m mysql -s <period>
  ```

  E.g.: ```k8s-period-metricbeat -p deploy/mysql -m mysql -s 10s```

### SSH Server

- Cubebeat

  ```console
  k8s-period-cubebeat -p deploy/ssh-server -s <period>
  ```

  E.g.: ```k8s-period-cubebeat -p deploy/ssh-server -s 10s```

## System

- Metricbeat

  ```console
  k8s-period-metricbeat -p deploy/apache -m system -s <period>
  k8s-period-metricbeat -p deploy/mysql -m system -s <period>
  k8s-period-metricbeat -p deploy/ssh-server -m system -s <period>
  ```

  E.g.:

  ```console
  k8s-period-metricbeat -p deploy/apache -m system -s 10s
  k8s-period-metricbeat -p deploy/mysql -m system -s 10s
  k8s-period-metricbeat -p deploy/ssh-server -m system -s 10s
  ```

## Useful commands

- Update pods (works only if the pods are already create).

   ```console
   kubectl replace -f ./pod
   ```

- Delete all pods instance (they will be recreated automatically by k8s)

   ```console
   kubectl delete pod -all -n guard-kube
   ```

- Delete all pods (they will NOT be recreated automatically by k8s)

   ```console
   kubectl delete deployment -all -n guard-kube
   ```

- Delete all configMaps

   ```console
   kubectl delete configmap -all -n guard-kube
   ```

- Delete all services
   ```console
   kubectl delete service -all -n guard-kube
   ```

## Utilties

- ```k8s``` - shortcut for ```kubectl -n guard-kube```.
- ```k8s-get``` - shortcut for ```k8s get -o wide```.
- ```k8s-desc``` - shortcut for ```k8s describe pods```.
- ```k8s-log``` - shortcut for ```k8s logs```.
- ```k8s-pod``` - shortcut for ```k8s-get pods```.
- ```k8s-serv``` - shortcut for ```k8s-get services```.
- ```k8s-map``` - shortcut for ```k8s-get configmaps```.

- ```k8s-start``` - Start the demo.
-
- ```k8s-frwd``` -t <target> - port forwarding for <target>. Possible values: elastic, kibana.

### ```period```

- ```k8s-period-filebeat``` -p <pod> -s <period> - sets the <period> (e.g. 10s) for ```filebeat``` in <pod>.
- ```k8s-period-metricbeat``` -p <pod> -m <module> -s <period> - sets the <period> (e.g. 10s) for <module> of ```metricbeat``` in <pod>.
- ```k8s-period-cubebeat``` -p <pod> -s <period> - sets the <period> (e.g. 10s) for ```cubebeat``` in <pod>.

- ```k8s-period-filebeat``` -p <pod> - gets the __period__ (e.g. 10s) for ```filebeat``` in <pod>.
- ```k8s-period-metricbeat``` -p <pod> -m <module> - gets the __period__ (e.g. 10s) for <module> of ```metricbeat``` in <pod> pod.
- ```k8s-period-cubebeat``` -p <pod> - gets the __period__ (e.g. 10s) for ```cubebeat``` in <pod>.
