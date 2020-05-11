# Demo Step

For each steps see the ```Apache HTTP Server```, ```Jitter```, and ```Latency``` dashboards in ```kibana``` at ```localhost:5061```.

## Apache

1. In a shell, generate the traffic with 10 request per second.

   ```console
   k8s-gen-apache -n 10
   ```

   See the dashboards.

2. In a shell, set the period to 5 seconds.

   ```console
   k8s-period-filebeat -p deploy/apache -s 5s
   ```

   See the dashboards.

3. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-filebeat -p deploy/apache -s 20s
   ```

   See the dashboards.

4. Stop the generator of step 1.
   In the same shell of step 1, generate the traffic with 100 request per second.

   ```console
   k8s-gen-apache -n 100
   ```

   See the dashboards.

5. In the same shell of step 2, set the period to 5 seconds.

   ```console
   k8s-period-filebeat -p deploy/apache -s 5s
   ```

   See the dashboards.

6. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-filebeat -p deploy/apache -s 20s
   ```

   See the dashboards.

7. Stop the generator of step 4.
   In the same shell of step 4, generate the traffic with 1000 request per second.

   ```console
   k8s-gen-apache -n 100
   ```

   See the dashboards.

8. In the same shell of step 2, set the period to 5 seconds.

   ```console
   $k8s-period-filebeat -p deploy/apache -s 5s
   ```

   See the dashboards.

9. In the same shell of step 2, set the period to 20 seconds.

   ```console
   $k8s-period-filebeat -p deploy/apache -s 20s
   ```

   See the dashboards.

## MySQL Server

For each steps see the ```MySQL Server```, ```Jitter```, and ```Latency``` dashboards in ```kibana``` at ```localhost:5061```.

1. In a shell, generate the traffic with 10 commands and 1 users per second.

   ```console
   k8s-gen-mysql -c 10 -u 1
   ```

   See the dashboards.

2. In a shell, set the period to 5 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 5s
   ```

   See the dashboards.

3. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 20s
   ```

   See the dashboards.

4. Stop the generator of step 1.
   In the same shell of step 1, generate the traffic with 10 commands and 10 users per second.

   ```console
   k8s-gen-mysql -c 10 -u 10
   ```

   See the dashboards.

5. In the same shell of step 2, set the period to 5 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 5s
   ```

   See the dashboards.

6. In the same shell of step 2, the period to 20 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 20s
   ```

   See the dashboards.

7. Stop the generator of step 4.
   In the same shell of step 4, generate the traffic with 100 commands and 10 users per second.

   ```console
   k8s-gen-mysql -c 100 -u 10
   ```

   See the dashboards.

8. In the same shell of step 2, set the period to 5 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 5s
   ```

   See the dashboards.

9. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-metricbeat -p deploy/mysql -m mysql -s 20s
   ```

   See the dashboards.

## SSH Server / SynFlood

For each steps see the ```SSH Server```, ```Jitter```, and ```Latency``` dashboards in ```kibana``` at ```localhost:5061```.

1. No synflood attach.
   In a shell, generate the synflood attach with 100 requests per second.

   ```console
   k8s-gen-synflood -n 5000
    ```

   See the dashboards.

2. In a shell, set the period to 5 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 5s
   ```

   See the dashboards.

3. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 20s
   ```

   See the dashboards.

4. Stop the generator of step 1.
   Low/Medium level synflood attach.
   In the same shell of step 1, generate the synflood attach with 100000 requests per second.

   ```console
   k8s-gen-synflood -n 10000
   ```

   See the dashboards.

5. In the same shell of step 2, set the period to 5 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 5s
   ```

   See the dashboards.

6. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 20s
   ```

   See the dashboards.

7. Stop the generator of step 4.
   Medium/High level synflood attach.
   In the same shell of step 4, generate the traffic with 1000000 requests per second.

   ```console
   k8s-gen-synflood -n 100000
   ```

   See the dashboards.

8. In the same shell of step 2, set the period to 5 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 5s
   ```

   See the dashboards.

9. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-cubebeat -p deploy/ssh-server -s 20s
   ```

   See the dashboards.

## System

For each steps see the ```System - CPU / RAM```, ```System - Network```, ```Jitter```, and ```Latency``` dashboards in ```kibana``` at ```localhost:5061```.

1. In a shell, set the period to 5 seconds.

   ```console
   k8s-period-metricbeat -p deploy/apache -m system -s 5s
   k8s-period-metricbeat -p deploy/mysql -m system -s 5s
   k8s-period-metricbeat -p deploy/ssh-server -m system -s 5s
   ```

   See the dashboards.

2. In the same shell of step 2, set the period to 20 seconds.

   ```console
   k8s-period-metricbeat -p deploy/apache -m system -s 20s
   k8s-period-metricbeat -p deploy/mysql -m system -s 20s
   k8s-period-metricbeat -p deploy/ssh-server -m system -s 20s
   ```

   See the dashboards.
