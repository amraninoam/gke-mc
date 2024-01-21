# Overview
This code will install and configure GKE Multi-Cluster as described [here](https://cloud.google.com/kubernetes-engine/docs/how-to/enabling-multi-cluster-gateways)

# Requirements
1. Linux shell
2. Google Cloud account - you will need to add it to the .env file
3. [jq](https://jqlang.github.io/jq/)
4. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

# Installation
1. Copy .env.copy to .env and modify its values
2. Change all scripts to executables
    ```bash 
    find . -type f -name "*.sh" -exec chmod +x {} \;
3. Create the cluster-set
    ```bash 
    runme.sh
## Notes:
1. The script will enable the following APIs in your project:
    - cloudresourcemanager.googleapis.com</BR>
    - container.googleapis.com</BR>
    - dns.googleapis.com</BR>
    - gkehub.googleapis.com</BR>
    - multiclusteringress.googleapis.com</BR>
    - multiclusterservicediscovery.googleapis.com</BR>
    - trafficdirector.googleapis.com</BR>
2. The kubeconfig will be located in \~/.kube/demo-config, so it might be easier for you to run the command below in your session to use the /.kube/demo-config config file</BR>
```export KUBECONFIG=~/.kube/demo-config```

# Demo
## MC Services 
In this demo, we will see how we access the a store service within the cluster.<br/>
Notice the naming convention of *service.namespace*.svc.**clusterset**.local<br/>
1. **US-West to MC serviceimport**:<br/>
    **Connect from**:  *us-west-1*<br/>
    **Connect to**:  multicluster *store serviceimport* http://store.store.svc.clusterset.local:8080<br/>
    For that we will connect to a busybox pod running on *us-west-1* cluster and check the response.<br/>
    The expected response could be from either store services: us-west or us-east.
    ```bash
    echo 
    echo "Running MC service test from west:"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

2. **US-West to US-West MC serviceimport**:<br/>
    **Connect from**:  *us-west-1*<br/>
    **Connect to**:  multicluster store serviceimport on *us-west-1* http://store-west-1.store.svc.clusterset.local:8080<br/>
    For that we will connect to a busybox pod running on *us-west-1* cluster and check the response.<br/>
    The expected response should be only us-west.
    ```bash
    echo 
    echo "Running MC west service test from west:"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store-west-1.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

3. **US-West to US-East MC serviceimport**:<br/>
    **Connect from**:  *us-west-1*<br/>
    **Connect to**:  multicluster store serviceimport on *us-east-1* http://store-east-1.store.svc.clusterset.local:8080<br/>
    For that we will connect to a busybox pod running on *us-west-1* cluster and check the response.<br/>
    The expected response should be only us-east.
    ```bash
    echo 
    echo "Running MC east service test from west:"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store-east-1.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```
## MC Gateway 
In this demo, we will see that we hit the right cluster, according to our location.
When we connect from US-West, we access the US-West clutser
When we connect from US-East, we access the US-East clutser
When we connect from our PC, we access the US-East clutser (since its closer to IL)


First, get the gateway IP and set it to "VIP" parameter.
```bash
VIP=$(kubectl get gateways.gateway.networking.k8s.io external-http -o=jsonpath="{.status.addresses[0].value}" --context gke-west-1 --namespace store)
```

1. **US-West**: Connect to the store gateway from *us-west-1*. For that we will connect to a busybox pod running on *us-west-1* cluster and check the response<br/>
   **Connect from**:  *us-west-1*<br/>
   **Connect to**:  multicluster gateway<br/>
    ```bash
    echo 
    echo "Running gateway test from west:"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q --header \"Host: store.example.com\" http://$VIP -O-" | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```
2. **US-East**: Connect to the store gateway from *us-east-1*. For that we will connect to a busybox pod running on *us-east-1* cluster and check the response<br/>
   **Connect from**:  *us-east-1*<br/>
   **Connect to**:  multicluster gateway<br/>
    ```bash
    echo 
    echo "Running gateway test from east:"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        kubectl exec busybox --context gke-east-1 -- "/bin/sh" "-c" "wget -q --header \"Host: store.example.com\" http://$VIP -O-" | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

3. **Your PC**: Connect to the store gateway from *your PC*.<br/>
   **Connect from**:  *your pc*<br/>
   **Connect to**:  multicluster gateway<br/>
    ```bash
    echo 
    echo "Running gateway test from my pc"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        wget -q --header "Host: store.example.com" http://$VIP -O- | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

4. **Your PC**: Connect to the store gateway from *your PC*.<br/>
   **Connect from**:  *your pc*<br/>
   **Connect to**:  multicluster gateway on *west*<br/>
    ```bash
    echo 
    echo "Running gateway test from my pc to west"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        wget -q --header "Host: store.example.com" http://$VIP/west -O- | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

5. **Your PC**: Connect to the store gateway from *your PC*.<br/>
   **Connect from**:  *your pc*<br/>
   **Connect to**:  multicluster gateway on *east*<br/>
    ```bash
    echo 
    echo "Running gateway test from my pc to east"
    for i in {1..10}; do 
        echo -n "Iteration $i: ";
        wget -q --header "Host: store.example.com" http://$VIP/east -O- | jq -r '"Response from cluster: " + .cluster_name'
    done;
    ```

## Bonus
Scale the store deployment on the east cluster to 0, and check all previous demo steps.
```
kubectl scale deployment store -n store --context gke-west-1 --replicas=0
```


# Tear Down
1. destroy the cluster-set
    ```bash 
    destroy.sh
